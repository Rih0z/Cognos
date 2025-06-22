# SLM Engine 実装仕様：AI研究者要求統合

## AI研究者向けSLM（Small Language Model）エンジン実装

### 1. SLM Engine アーキテクチャ

#### 1.1 SLM Engine構造体定義
```c
// cognos-kernel/include/ai/slm_engine.h
#ifndef SLM_ENGINE_H
#define SLM_ENGINE_H

#define SLM_MAX_MODELS          8
#define SLM_MAX_INPUT_LENGTH    512
#define SLM_MAX_OUTPUT_LENGTH   1024
#define SLM_MODEL_MAGIC         0x534C4D45  // "SLME"

typedef enum {
    SLM_TYPE_NL_TO_SYSCALL = 1,  // 自然言語→システムコール変換
    SLM_TYPE_CODE_ANALYSIS = 2,  // コード解析
    SLM_TYPE_ERROR_DIAGNOSIS = 3, // エラー診断
    SLM_TYPE_OPTIMIZATION = 4    // 最適化提案
} slm_model_type_t;

typedef struct slm_model_header {
    uint32_t magic;              // SLM_MODEL_MAGIC
    uint32_t version;            // モデルバージョン
    uint32_t model_type;         // slm_model_type_t
    uint32_t model_size;         // モデルサイズ（バイト）
    uint32_t vocab_size;         // 語彙サイズ
    uint32_t hidden_size;        // 隠れ層サイズ
    uint32_t num_layers;         // レイヤー数
    uint32_t context_length;     // コンテキスト長
    uint8_t  model_name[64];     // モデル名
    uint32_t checksum;           // CRC32チェックサム
} slm_model_header_t;

typedef struct slm_model {
    slm_model_header_t header;
    void* weights;               // モデル重み
    void* vocab;                 // 語彙テーブル
    void* tokenizer;             // トークナイザー
    uint32_t ref_count;          // 参照カウント
    uint32_t last_used;          // 最終使用時刻
} slm_model_t;

typedef struct slm_inference_context {
    uint32_t model_id;
    float* input_embeddings;     // 入力埋め込み
    float* hidden_states;        // 隠れ状態
    float* attention_weights;    // アテンション重み
    uint32_t sequence_length;
    uint32_t position;
} slm_inference_context_t;

typedef struct slm_engine {
    slm_model_t models[SLM_MAX_MODELS];
    uint32_t model_count;
    slm_inference_context_t contexts[SLM_MAX_MODELS];
    
    // パフォーマンス統計
    uint64_t total_inferences;
    uint64_t total_inference_time;
    uint64_t cache_hits;
    uint64_t cache_misses;
    
    // キャッシュシステム
    struct {
        char input[SLM_MAX_INPUT_LENGTH];
        char output[SLM_MAX_OUTPUT_LENGTH];
        uint32_t model_id;
        uint64_t timestamp;
    } cache[256];
    uint32_t cache_size;
    
    spinlock_t lock;
} slm_engine_t;

// SLM Engine API
int slm_engine_init(slm_engine_t* engine, void* memory_base, size_t memory_size);
int slm_load_model(slm_engine_t* engine, const char* model_path, uint32_t model_type);
int slm_unload_model(slm_engine_t* engine, uint32_t model_id);
int slm_infer(slm_engine_t* engine, slm_inference_request_t* request);
int slm_get_model_info(slm_engine_t* engine, uint32_t model_id, slm_model_info_t* info);
void slm_engine_cleanup(slm_engine_t* engine);

#endif
```

#### 1.2 SLM Engine実装
```c
// cognos-kernel/src/ai/slm_engine.c
#include "slm_engine.h"
#include "ai_memory.h"

static slm_engine_t* global_slm_engine = NULL;

int slm_engine_init(slm_engine_t* engine, void* memory_base, size_t memory_size) {
    if (!engine || !memory_base || memory_size < SLM_POOL_SIZE) {
        return -EINVAL;
    }
    
    memset(engine, 0, sizeof(slm_engine_t));
    spin_lock_init(&engine->lock);
    
    // SLM専用メモリ初期化
    for (int i = 0; i < SLM_MAX_MODELS; i++) {
        engine->models[i].weights = NULL;
        engine->contexts[i].model_id = INVALID_MODEL_ID;
    }
    
    engine->model_count = 0;
    engine->cache_size = 0;
    
    global_slm_engine = engine;
    
    kprintf("SLM Engine initialized with %zu MB memory\n", memory_size / (1024*1024));
    return 0;
}

int slm_load_model(slm_engine_t* engine, const char* model_path, uint32_t model_type) {
    if (!engine || !model_path || engine->model_count >= SLM_MAX_MODELS) {
        return -EINVAL;
    }
    
    spin_lock(&engine->lock);
    
    // モデルファイル読み込み
    file_t* model_file = vfs_open(model_path, O_RDONLY);
    if (!model_file) {
        spin_unlock(&engine->lock);
        return -ENOENT;
    }
    
    // ヘッダー読み込み・検証
    slm_model_header_t header;
    if (vfs_read(model_file, &header, sizeof(header)) != sizeof(header)) {
        vfs_close(model_file);
        spin_unlock(&engine->lock);
        return -EIO;
    }
    
    if (header.magic != SLM_MODEL_MAGIC) {
        vfs_close(model_file);
        spin_unlock(&engine->lock);
        return -EINVAL;
    }
    
    // モデルメモリ割り当て
    void* model_memory = ai_memory_alloc(header.model_size, SLM_TYPE, CACHED);
    if (!model_memory) {
        vfs_close(model_file);
        spin_unlock(&engine->lock);
        return -ENOMEM;
    }
    
    // モデルデータ読み込み
    if (vfs_read(model_file, model_memory, header.model_size) != header.model_size) {
        ai_memory_free(model_memory);
        vfs_close(model_file);
        spin_unlock(&engine->lock);
        return -EIO;
    }
    
    vfs_close(model_file);
    
    // モデル構造初期化
    uint32_t model_id = engine->model_count;
    slm_model_t* model = &engine->models[model_id];
    
    model->header = header;
    model->weights = model_memory;
    model->vocab = (uint8_t*)model_memory + header.hidden_size * header.num_layers * sizeof(float);
    model->tokenizer = (uint8_t*)model->vocab + header.vocab_size * sizeof(uint32_t);
    model->ref_count = 0;
    model->last_used = get_system_time();
    
    engine->model_count++;
    
    spin_unlock(&engine->lock);
    
    kprintf("SLM Model loaded: %s (ID: %u, Type: %u)\n", 
            header.model_name, model_id, model_type);
    
    return model_id;
}

int slm_infer(slm_engine_t* engine, slm_inference_request_t* request) {
    if (!engine || !request || request->model_id >= engine->model_count) {
        return -EINVAL;
    }
    
    uint64_t start_time = rdtsc();
    
    // キャッシュ確認
    int cache_result = slm_cache_lookup(engine, request);
    if (cache_result >= 0) {
        engine->cache_hits++;
        return cache_result;
    }
    engine->cache_misses++;
    
    spin_lock(&engine->lock);
    
    slm_model_t* model = &engine->models[request->model_id];
    slm_inference_context_t* context = &engine->contexts[request->model_id];
    
    // トークン化
    uint32_t tokens[SLM_MAX_INPUT_LENGTH / 4];
    int token_count = slm_tokenize(model, request->input, tokens, sizeof(tokens) / sizeof(uint32_t));
    if (token_count < 0) {
        spin_unlock(&engine->lock);
        return token_count;
    }
    
    // 推論実行
    float logits[model->header.vocab_size];
    int result = slm_forward_pass(model, context, tokens, token_count, logits);
    if (result < 0) {
        spin_unlock(&engine->lock);
        return result;
    }
    
    // デトークン化
    uint32_t output_tokens[SLM_MAX_OUTPUT_LENGTH / 4];
    int output_token_count = slm_sample_tokens(logits, model->header.vocab_size, 
                                               output_tokens, sizeof(output_tokens) / sizeof(uint32_t));
    
    result = slm_detokenize(model, output_tokens, output_token_count, 
                           request->output, request->output_size);
    
    if (result >= 0) {
        request->output_len = result;
        
        // キャッシュに保存
        slm_cache_store(engine, request);
        
        // 統計更新
        model->ref_count++;
        model->last_used = get_system_time();
        engine->total_inferences++;
        engine->total_inference_time += rdtsc() - start_time;
    }
    
    spin_unlock(&engine->lock);
    return result;
}
```

### 2. 自然言語→システムコール変換特化実装

#### 2.1 自然言語パターンマッチング
```c
// cognos-kernel/src/ai/nl_to_syscall.c
#include "slm_engine.h"

typedef struct nl_pattern {
    const char* pattern;
    const char* syscall_template;
    uint32_t confidence;
} nl_pattern_t;

// 事前定義パターン（高速パフォーマンス用）
static const nl_pattern_t nl_patterns[] = {
    // ファイル操作
    {"ファイル*読", "sys_open(\"%s\", O_RDONLY); sys_read(%d, buf, size); sys_close(%d);", 95},
    {"ファイル*書", "sys_open(\"%s\", O_WRONLY|O_CREAT); sys_write(%d, data, len); sys_close(%d);", 95},
    {"ファイル*削除", "sys_unlink(\"%s\");", 98},
    {"ファイル*コピー", "copy_file(\"%s\", \"%s\");", 90},
    
    // プロセス管理
    {"プロセス*一覧", "sys_ps(); sys_getpid();", 95},
    {"プロセス*終了", "sys_kill(%d, SIGTERM);", 90},
    {"プロセス*実行", "sys_execve(\"%s\", argv, envp);", 85},
    
    // システム情報
    {"メモリ*使用量", "sys_meminfo(); sys_getrlimit(RLIMIT_AS);", 95},
    {"CPU*使用率", "sys_cpuinfo(); sys_getloadavg();", 90},
    {"ディスク*容量", "sys_statvfs(\"/\");", 95},
    
    // ネットワーク
    {"ネット*接続", "sys_socket(AF_INET, SOCK_STREAM); sys_connect();", 85},
    {"ポート*開放", "sys_socket(AF_INET, SOCK_STREAM); sys_bind(); sys_listen();", 85},
    
    {NULL, NULL, 0}
};

int nl_pattern_match(const char* input, char* output, size_t output_size) {
    // 高速パターンマッチング（~50μs）
    for (int i = 0; nl_patterns[i].pattern != NULL; i++) {
        if (simple_pattern_match(input, nl_patterns[i].pattern)) {
            strncpy(output, nl_patterns[i].syscall_template, output_size);
            return nl_patterns[i].confidence;
        }
    }
    
    // SLM推論フォールバック（~10ms）
    return slm_infer_nl_to_syscall(input, output, output_size);
}

static bool simple_pattern_match(const char* input, const char* pattern) {
    // 簡単なワイルドカードマッチング
    const char* p = pattern;
    const char* s = input;
    
    while (*p && *s) {
        if (*p == '*') {
            p++;
            while (*s && !strchr(p, *s)) s++;
        } else if (*p == *s) {
            p++;
            s++;
        } else {
            return false;
        }
    }
    
    return (*p == '\0' || (*p == '*' && *(p+1) == '\0'));
}

int slm_infer_nl_to_syscall(const char* input, char* output, size_t output_size) {
    slm_inference_request_t request = {
        .model_id = NL_TO_SYSCALL_MODEL_ID,
        .input = input,
        .input_len = strlen(input),
        .output = output,
        .output_size = output_size
    };
    
    return slm_infer(global_slm_engine, &request);
}
```

#### 2.2 最適化されたトークナイザー
```c
// cognos-kernel/src/ai/slm_tokenizer.c

typedef struct token_entry {
    uint32_t token_id;
    char text[16];
    uint8_t length;
} token_entry_t;

// 日本語・英語システムコール特化語彙
static const token_entry_t system_vocab[] = {
    // システムコール
    {1, "sys_", 4}, {2, "open", 4}, {3, "read", 4}, {4, "write", 5},
    {5, "close", 5}, {6, "unlink", 6}, {7, "mkdir", 5}, {8, "rmdir", 5},
    
    // 日本語動詞
    {100, "読む", 6}, {101, "書く", 6}, {102, "削除", 6}, {103, "作成", 6},
    {104, "実行", 6}, {105, "終了", 6}, {106, "開く", 6}, {107, "閉じる", 9},
    
    // 日本語名詞
    {200, "ファイル", 12}, {201, "プロセス", 12}, {202, "メモリ", 9},
    {203, "CPU", 3}, {204, "ディスク", 12}, {205, "ネット", 9},
    
    // 共通語
    {300, "を", 3}, {301, "に", 3}, {302, "で", 3}, {303, "から", 6},
    {304, "まで", 6}, {305, "する", 6}, {306, "です", 6}, {307, "ます", 6},
    
    {0, "", 0}
};

int slm_tokenize(slm_model_t* model, const char* input, uint32_t* tokens, size_t max_tokens) {
    const char* p = input;
    size_t token_count = 0;
    
    while (*p && token_count < max_tokens) {
        // 最長マッチング
        int best_match_len = 0;
        uint32_t best_token_id = 0;
        
        for (int i = 0; system_vocab[i].token_id != 0; i++) {
            if (strncmp(p, system_vocab[i].text, system_vocab[i].length) == 0) {
                if (system_vocab[i].length > best_match_len) {
                    best_match_len = system_vocab[i].length;
                    best_token_id = system_vocab[i].token_id;
                }
            }
        }
        
        if (best_match_len > 0) {
            tokens[token_count++] = best_token_id;
            p += best_match_len;
        } else {
            // 未知文字は特殊トークンとして処理
            tokens[token_count++] = 1000 + (uint8_t)*p;
            p++;
        }
    }
    
    return token_count;
}

int slm_detokenize(slm_model_t* model, uint32_t* tokens, size_t token_count, 
                   char* output, size_t output_size) {
    size_t output_len = 0;
    
    for (size_t i = 0; i < token_count && output_len < output_size - 1; i++) {
        uint32_t token_id = tokens[i];
        
        // 語彙テーブル検索
        for (int j = 0; system_vocab[j].token_id != 0; j++) {
            if (system_vocab[j].token_id == token_id) {
                size_t text_len = system_vocab[j].length;
                if (output_len + text_len < output_size) {
                    memcpy(output + output_len, system_vocab[j].text, text_len);
                    output_len += text_len;
                }
                break;
            }
        }
    }
    
    output[output_len] = '\0';
    return output_len;
}
```

### 3. SLM推論エンジン（軽量実装）

#### 3.1 Forward Pass実装
```c
// cognos-kernel/src/ai/slm_inference.c

typedef struct slm_layer {
    float* weights;              // [hidden_size x hidden_size]
    float* bias;                 // [hidden_size]
    float* attention_weights;    // [hidden_size x hidden_size]
} slm_layer_t;

int slm_forward_pass(slm_model_t* model, slm_inference_context_t* context, 
                     uint32_t* tokens, int token_count, float* output_logits) {
    
    uint32_t hidden_size = model->header.hidden_size;
    uint32_t vocab_size = model->header.vocab_size;
    uint32_t num_layers = model->header.num_layers;
    
    // 入力埋め込み
    float* embeddings = context->input_embeddings;
    for (int i = 0; i < token_count; i++) {
        uint32_t token_id = tokens[i];
        if (token_id >= vocab_size) continue;
        
        // 埋め込みテーブルから取得
        float* embedding_vector = (float*)model->vocab + token_id * hidden_size;
        memcpy(embeddings + i * hidden_size, embedding_vector, hidden_size * sizeof(float));
    }
    
    float* hidden_states = context->hidden_states;
    memcpy(hidden_states, embeddings, token_count * hidden_size * sizeof(float));
    
    // レイヤー毎の処理
    slm_layer_t* layers = (slm_layer_t*)model->weights;
    
    for (uint32_t layer = 0; layer < num_layers; layer++) {
        slm_layer_t* current_layer = &layers[layer];
        
        // Self-Attention（簡略版）
        slm_self_attention(hidden_states, current_layer->attention_weights, 
                          token_count, hidden_size);
        
        // Feed Forward
        slm_feed_forward(hidden_states, current_layer->weights, current_layer->bias,
                        token_count, hidden_size);
        
        // Layer Normalization
        slm_layer_norm(hidden_states, token_count, hidden_size);
    }
    
    // 出力層
    slm_output_projection(hidden_states + (token_count - 1) * hidden_size, 
                         (float*)model->weights + num_layers * sizeof(slm_layer_t),
                         output_logits, hidden_size, vocab_size);
    
    return 0;
}

static void slm_self_attention(float* hidden_states, float* attention_weights,
                              int seq_len, int hidden_size) {
    // 簡略化されたアテンション実装（パフォーマンス重視）
    float attention_output[seq_len * hidden_size];
    
    for (int i = 0; i < seq_len; i++) {
        float* query = hidden_states + i * hidden_size;
        
        for (int j = 0; j < hidden_size; j++) {
            float sum = 0.0f;
            
            for (int k = 0; k <= i; k++) {  // Causal attention
                float* key = hidden_states + k * hidden_size;
                float attention_score = vector_dot_product(query, key, hidden_size);
                sum += attention_score * hidden_states[k * hidden_size + j];
            }
            
            attention_output[i * hidden_size + j] = sum;
        }
    }
    
    memcpy(hidden_states, attention_output, seq_len * hidden_size * sizeof(float));
}

static void slm_feed_forward(float* hidden_states, float* weights, float* bias,
                            int seq_len, int hidden_size) {
    for (int i = 0; i < seq_len; i++) {
        float* input = hidden_states + i * hidden_size;
        
        // Linear transformation + ReLU
        for (int j = 0; j < hidden_size; j++) {
            float sum = bias[j];
            for (int k = 0; k < hidden_size; k++) {
                sum += input[k] * weights[j * hidden_size + k];
            }
            input[j] = fmaxf(0.0f, sum);  // ReLU activation
        }
    }
}

static float vector_dot_product(float* a, float* b, int size) {
    float result = 0.0f;
    for (int i = 0; i < size; i++) {
        result += a[i] * b[i];
    }
    return result;
}
```

### 4. パフォーマンス最適化

#### 4.1 キャッシュシステム
```c
// cognos-kernel/src/ai/slm_cache.c

#define CACHE_HASH_SIZE     256
#define CACHE_MAX_AGE_MS    300000  // 5分

typedef struct cache_bucket {
    char input_hash[32];
    char output[SLM_MAX_OUTPUT_LENGTH];
    uint32_t output_len;
    uint64_t timestamp;
    uint32_t access_count;
    struct cache_bucket* next;
} cache_bucket_t;

static cache_bucket_t* cache_table[CACHE_HASH_SIZE];
static spinlock_t cache_lock;

int slm_cache_lookup(slm_engine_t* engine, slm_inference_request_t* request) {
    uint32_t hash = simple_hash(request->input, request->input_len);
    uint32_t bucket_index = hash % CACHE_HASH_SIZE;
    
    spin_lock(&cache_lock);
    
    cache_bucket_t* bucket = cache_table[bucket_index];
    while (bucket) {
        if (memcmp(bucket->input_hash, &hash, sizeof(hash)) == 0) {
            // ヒット確認
            uint64_t current_time = get_system_time();
            if (current_time - bucket->timestamp < CACHE_MAX_AGE_MS * 1000) {
                // キャッシュヒット
                memcpy(request->output, bucket->output, bucket->output_len);
                request->output_len = bucket->output_len;
                bucket->access_count++;
                
                spin_unlock(&cache_lock);
                return bucket->output_len;
            } else {
                // 期限切れ - エントリ削除
                cache_table[bucket_index] = bucket->next;
                kfree(bucket);
                break;
            }
        }
        bucket = bucket->next;
    }
    
    spin_unlock(&cache_lock);
    return -1;  // キャッシュミス
}

void slm_cache_store(slm_engine_t* engine, slm_inference_request_t* request) {
    uint32_t hash = simple_hash(request->input, request->input_len);
    uint32_t bucket_index = hash % CACHE_HASH_SIZE;
    
    cache_bucket_t* new_bucket = kmalloc(sizeof(cache_bucket_t));
    if (!new_bucket) return;
    
    memcpy(new_bucket->input_hash, &hash, sizeof(hash));
    memcpy(new_bucket->output, request->output, request->output_len);
    new_bucket->output_len = request->output_len;
    new_bucket->timestamp = get_system_time();
    new_bucket->access_count = 1;
    
    spin_lock(&cache_lock);
    new_bucket->next = cache_table[bucket_index];
    cache_table[bucket_index] = new_bucket;
    spin_unlock(&cache_lock);
}

static uint32_t simple_hash(const char* data, size_t len) {
    uint32_t hash = 0x811c9dc5;  // FNV-1a hash
    for (size_t i = 0; i < len; i++) {
        hash ^= (uint8_t)data[i];
        hash *= 0x01000193;
    }
    return hash;
}
```

### 5. 統合テストとベンチマーク

#### 5.1 SLM性能テスト
```c
// cognos-kernel/tests/slm_performance_test.c

void test_slm_performance(void) {
    slm_engine_t engine;
    slm_engine_init(&engine, (void*)SLM_POOL_BASE, SLM_POOL_SIZE);
    
    // テストモデル読み込み
    int model_id = slm_load_model(&engine, "/models/nl_to_syscall.slm", SLM_TYPE_NL_TO_SYSCALL);
    assert(model_id >= 0);
    
    const char* test_inputs[] = {
        "ファイルを読み込んでください",
        "メモリ使用量を確認",
        "プロセス一覧を表示",
        "ネットワーク接続状態を調べる",
        "ディスク容量を確認"
    };
    
    // 性能測定
    uint64_t total_time = 0;
    int test_count = sizeof(test_inputs) / sizeof(test_inputs[0]);
    
    for (int i = 0; i < test_count; i++) {
        char output[1024];
        slm_inference_request_t request = {
            .model_id = model_id,
            .input = test_inputs[i],
            .input_len = strlen(test_inputs[i]),
            .output = output,
            .output_size = sizeof(output)
        };
        
        uint64_t start = rdtsc();
        int result = slm_infer(&engine, &request);
        uint64_t end = rdtsc();
        
        assert(result >= 0);
        total_time += (end - start);
        
        kprintf("Test %d: %s -> %s (%llu cycles)\n", 
                i, test_inputs[i], output, end - start);
    }
    
    kprintf("Average inference time: %llu cycles\n", total_time / test_count);
    kprintf("Expected: < 10ms per inference\n");
    
    // キャッシュ効果テスト
    uint64_t cached_start = rdtsc();
    slm_inference_request_t cached_request = {
        .model_id = model_id,
        .input = test_inputs[0],  // 既にキャッシュされているはず
        .input_len = strlen(test_inputs[0]),
        .output = output,
        .output_size = sizeof(output)
    };
    slm_infer(&engine, &cached_request);
    uint64_t cached_end = rdtsc();
    
    kprintf("Cached inference time: %llu cycles\n", cached_end - cached_start);
    kprintf("Expected: < 1000 cycles (cache hit)\n");
}
```

このSLM Engine実装により、AI研究者の要求する高速で効率的な自然言語処理機能がCognos OSに統合されます。