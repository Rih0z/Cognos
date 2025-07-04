# OS研究者からのハイブリッド検証アーキテクチャ提案 - 2025年1月21日

## ハイブリッド検証アーキテクチャ

### 1. 軽量コンテナ層
- gVisor/Firecracker型の軽量VM
- AI生成コードを隔離実行
- システムコール監視で異常検出

### 2. eBPFは補助的使用
- パフォーマンスメトリクス収集のみ
- 検証ロジックはユーザー空間
- オーバーヘッド最小化（<1%）

### 3. 段階的信頼度向上
- 初回：完全隔離環境
- 信頼度上昇後：軽量監視のみ
- 実績蓄積後：ネイティブ実行

この設計により、セキュリティと性能のバランスを実現できます。