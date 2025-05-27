# カロリー管理アプリ バックエンド設計書

## 1. 概要

### 1.1 目的
本ドキュメントは、カロリー管理アプリ「ずぼらカロリー」のバックエンドシステムの詳細設計を定義するものである。システム要件定義書に基づき、データモデル、API設計、データベース構造、およびその他のバックエンドコンポーネントの技術的詳細を提供する。

### 1.2 スコープ
本設計書は以下の要素を対象とする：
- データベース設計
- APIエンドポイント設計
- バックエンドアーキテクチャ
- データアクセス層
- ビジネスロジック層
- セキュリティ実装
- パフォーマンス最適化戦略

### 1.3 前提条件
- ユーザーデータはプライマリとして端末内に保存
- オプションのクラウド同期機能
- オフライン環境でも基本機能が利用可能
- データの所有権はユーザーに帰属

## 2. アーキテクチャ設計

### 2.1 全体アーキテクチャ

```
+------------------------------------------+
|              モバイルアプリ               |
+------------------------------------------+
                    |
                    | ローカルデータアクセス
                    v
+------------------------------------------+
|           ローカルデータベース             |
|          (SQLite / Realm)               |
+------------------------------------------+
                    |
                    | オプショナル同期
                    v
+------------------------------------------+
|             バックエンドサーバー            |
|                                          |
| +----------------------------------+     |
| |          APIレイヤー              |     |
| | (RESTful API / GraphQL)         |     |
| +----------------------------------+     |
|                  |                       |
| +----------------------------------+     |
| |        ビジネスロジック層          |     |
| | (Services, Validators)          |     |
| +----------------------------------+     |
|                  |                       |
| +----------------------------------+     |
| |        データアクセス層            |     |
| | (Repositories, ORM)             |     |
| +----------------------------------+     |
|                  |                       |
| +----------------------------------+     |
| |        データベース               |     |
| | (PostgreSQL / MongoDB)          |     |
| +----------------------------------+     |
+------------------------------------------+
```

### 2.2 技術スタック選定

#### 2.2.1 バックエンドフレームワーク
- **選定技術**: FastAPI
- **選定理由**:
  - 高パフォーマンス（非同期処理サポート）
  - 自動APIドキュメント生成
  - Pythonの簡潔な構文と開発速度
  - 型ヒントによる堅牢性

#### 2.2.2 データベース
- **ローカル**: SQLite / Realm
- **クラウド**: PostgreSQL
- **選定理由**:
  - SQLite: 組み込みデータベースとして軽量で信頼性が高い
  - Realm: モバイル向け最適化とオフラインファーストアプローチ
  - PostgreSQL: 関係データの堅牢な管理と拡張性

#### 2.2.3 認証
- **選定技術**: JWT (JSON Web Tokens)
- **選定理由**:
  - ステートレス認証
  - クロスプラットフォーム互換性
  - スケーラビリティ

#### 2.2.4 API設計
- **選定アプローチ**: RESTful API + OpenAPI仕様
- **選定理由**:
  - 広く採用されている標準
  - クライアント実装の容易さ
  - 自動ドキュメント生成と検証

### 2.3 コンポーネント設計

#### 2.3.1 APIレイヤー
- リクエスト処理
- レスポンスフォーマット
- エラーハンドリング
- 認証・認可

#### 2.3.2 ビジネスロジック層
- ユーザー管理サービス
- カロリー計算サービス
- 体重管理サービス
- データ分析サービス
- 同期サービス

#### 2.3.3 データアクセス層
- リポジトリパターン実装
- ORM/ODMマッピング
- クエリ最適化
- トランザクション管理

#### 2.3.4 インフラストラクチャ層
- データベース接続管理
- キャッシュ管理
- ロギング
- 設定管理

## 3. データベース設計

### 3.1 ER図

```
+-------------+      +---------------+      +-------------+
|    User     |      |     Food      |      |   Weight    |
+-------------+      +---------------+      +-------------+
| userId (PK) |<--+  | foodId (PK)   |   +->| weightId(PK)|
| name        |   |  | name          |   |  | userId (FK) |
| height      |   |  | calories      |   |  | date        |
| targetWeight|   |  | category      |   |  | value       |
| targetCal   |   |  | isCustom      |   |  | note        |
| createdAt   |   |  | createdAt     |   |  | createdAt   |
| updatedAt   |   |  | updatedAt     |   |  | updatedAt   |
+-------------+   |  +---------------+   |  +-------------+
                  |                      |
                  |  +---------------+   |
                  |  |  FoodEntry    |   |
                  |  +---------------+   |
                  +--| entryId (PK)  |   |
                     | userId (FK)   |---+
                     | foodId (FK)   |
                     | date          |
                     | quantity      |
                     | mealType      |
                     | calories      |
                     | note          |
                     | createdAt     |
                     | updatedAt     |
                     +---------------+
```

### 3.2 テーブル定義

#### 3.2.1 User テーブル

| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|------|------|
| userId | VARCHAR(36) | PRIMARY KEY | ユーザーID (UUID) |
| name | VARCHAR(100) | NOT NULL | ユーザー名 |
| height | DECIMAL(5,2) | NULL | 身長 (cm) |
| targetWeight | DECIMAL(5,2) | NULL | 目標体重 (kg) |
| targetCalories | INTEGER | NULL | 目標カロリー (kcal) |
| createdAt | TIMESTAMP | NOT NULL | 作成日時 |
| updatedAt | TIMESTAMP | NOT NULL | 更新日時 |

**インデックス**:
- PRIMARY KEY (userId)

#### 3.2.2 Food テーブル

| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|------|------|
| foodId | VARCHAR(36) | PRIMARY KEY | 食品ID (UUID) |
| name | VARCHAR(100) | NOT NULL | 食品名 |
| calories | INTEGER | NOT NULL | カロリー値 (kcal) |
| category | VARCHAR(50) | NULL | カテゴリ |
| isCustom | BOOLEAN | NOT NULL | ユーザー作成かどうか |
| createdAt | TIMESTAMP | NOT NULL | 作成日時 |
| updatedAt | TIMESTAMP | NOT NULL | 更新日時 |

**インデックス**:
- PRIMARY KEY (foodId)
- INDEX idx_food_name (name)
- INDEX idx_food_category (category)

#### 3.2.3 FoodEntry テーブル

| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|------|------|
| entryId | VARCHAR(36) | PRIMARY KEY | 記録ID (UUID) |
| userId | VARCHAR(36) | NOT NULL, FOREIGN KEY | ユーザーID |
| foodId | VARCHAR(36) | NOT NULL, FOREIGN KEY | 食品ID |
| date | DATE | NOT NULL | 記録日 |
| quantity | DECIMAL(5,2) | NOT NULL DEFAULT 1 | 数量 |
| mealType | VARCHAR(20) | NOT NULL | 食事タイプ (朝食/昼食/夕食/間食) |
| calories | INTEGER | NOT NULL | 合計カロリー (kcal) |
| note | TEXT | NULL | メモ |
| createdAt | TIMESTAMP | NOT NULL | 作成日時 |
| updatedAt | TIMESTAMP | NOT NULL | 更新日時 |

**インデックス**:
- PRIMARY KEY (entryId)
- FOREIGN KEY (userId) REFERENCES User(userId)
- FOREIGN KEY (foodId) REFERENCES Food(foodId)
- INDEX idx_entry_user_date (userId, date)
- INDEX idx_entry_date (date)

#### 3.2.4 Weight テーブル

| カラム名 | データ型 | 制約 | 説明 |
|---------|---------|------|------|
| weightId | VARCHAR(36) | PRIMARY KEY | 記録ID (UUID) |
| userId | VARCHAR(36) | NOT NULL, FOREIGN KEY | ユーザーID |
| date | DATE | NOT NULL | 記録日 |
| value | DECIMAL(5,2) | NOT NULL | 体重値 (kg) |
| note | TEXT | NULL | メモ |
| createdAt | TIMESTAMP | NOT NULL | 作成日時 |
| updatedAt | TIMESTAMP | NOT NULL | 更新日時 |

**インデックス**:
- PRIMARY KEY (weightId)
- FOREIGN KEY (userId) REFERENCES User(userId)
- UNIQUE INDEX idx_weight_user_date (userId, date)
- INDEX idx_weight_date (date)

### 3.3 データベースマイグレーション戦略

#### 3.3.1 マイグレーションツール
- **選定ツール**: Alembic
- **選定理由**: SQLAlchemyとの統合、バージョン管理、ロールバック機能

#### 3.3.2 マイグレーションプロセス
1. 初期スキーマ作成
2. 変更検出と自動マイグレーションスクリプト生成
3. マイグレーション実行とバージョン管理
4. 必要に応じたロールバック

#### 3.3.3 データ移行戦略
- スキーマ変更時のデータ保持
- バージョン間の互換性維持
- 段階的なデータ変換

## 4. API設計

### 4.1 API概要

#### 4.1.1 基本情報
- **ベースURL**: `/api/v1`
- **フォーマット**: JSON
- **認証方式**: JWT Bearer Token
- **エラーレスポンス形式**:
  ```json
  {
    "status": "error",
    "code": 400,
    "message": "エラーメッセージ",
    "details": { ... }
  }
  ```
- **成功レスポンス形式**:
  ```json
  {
    "status": "success",
    "data": { ... }
  }
  ```

#### 4.1.2 API バージョニング戦略
- URLパスによるバージョニング (`/api/v1/...`)
- 後方互換性の維持
- 段階的な古いバージョンの廃止

### 4.2 認証API

#### 4.2.1 ユーザー登録
- **エンドポイント**: `POST /api/v1/auth/register`
- **説明**: 新規ユーザー登録
- **リクエスト**:
  ```json
  {
    "name": "山田太郎",
    "email": "yamada@example.com",
    "password": "securePassword123"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "email": "yamada@example.com",
      "createdAt": "2023-05-20T12:34:56Z"
    }
  }
  ```

#### 4.2.2 ログイン
- **エンドポイント**: `POST /api/v1/auth/login`
- **説明**: ユーザーログイン
- **リクエスト**:
  ```json
  {
    "email": "yamada@example.com",
    "password": "securePassword123"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "expiresIn": 3600
    }
  }
  ```

#### 4.2.3 トークンリフレッシュ
- **エンドポイント**: `POST /api/v1/auth/refresh`
- **説明**: アクセストークンの更新
- **リクエスト**:
  ```json
  {
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": 3600
    }
  }
  ```

### 4.3 ユーザーAPI

#### 4.3.1 ユーザープロフィール取得
- **エンドポイント**: `GET /api/v1/users/profile`
- **説明**: ログインユーザーのプロフィール情報取得
- **認証**: 必須
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "height": 175.5,
      "targetWeight": 70.0,
      "targetCalories": 2000,
      "createdAt": "2023-05-20T12:34:56Z",
      "updatedAt": "2023-05-21T09:12:34Z"
    }
  }
  ```

#### 4.3.2 ユーザープロフィール更新
- **エンドポイント**: `PUT /api/v1/users/profile`
- **説明**: ユーザープロフィール情報の更新
- **認証**: 必須
- **リクエスト**:
  ```json
  {
    "name": "山田太郎",
    "height": 175.5,
    "targetWeight": 68.0,
    "targetCalories": 1800
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "name": "山田太郎",
      "height": 175.5,
      "targetWeight": 68.0,
      "targetCalories": 1800,
      "updatedAt": "2023-05-22T10:11:12Z"
    }
  }
  ```

### 4.4 食品API

#### 4.4.1 食品一覧取得
- **エンドポイント**: `GET /api/v1/foods`
- **説明**: 食品データの一覧取得
- **認証**: 必須
- **クエリパラメータ**:
  - `query`: 検索キーワード (オプション)
  - `category`: カテゴリでフィルタ (オプション)
  - `page`: ページ番号 (デフォルト: 1)
  - `limit`: 1ページあたりの件数 (デフォルト: 20)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "items": [
        {
          "foodId": "550e8400-e29b-41d4-a716-446655440001",
          "name": "ごはん（茶碗1杯）",
          "calories": 240,
          "category": "主食",
          "isCustom": false
        },
        {
          "foodId": "550e8400-e29b-41d4-a716-446655440002",
          "name": "食パン（6枚切り1枚）",
          "calories": 177,
          "category": "主食",
          "isCustom": false
        }
      ],
      "total": 245,
      "page": 1,
      "limit": 20,
      "pages": 13
    }
  }
  ```

#### 4.4.2 食品詳細取得
- **エンドポイント**: `GET /api/v1/foods/{foodId}`
- **説明**: 特定の食品データの詳細取得
- **認証**: 必須
- **パスパラメータ**:
  - `foodId`: 食品ID
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "foodId": "550e8400-e29b-41d4-a716-446655440001",
      "name": "ごはん（茶碗1杯）",
      "calories": 240,
      "category": "主食",
      "isCustom": false,
      "createdAt": "2023-05-01T00:00:00Z",
      "updatedAt": "2023-05-01T00:00:00Z"
    }
  }
  ```

#### 4.4.3 カスタム食品作成
- **エンドポイント**: `POST /api/v1/foods`
- **説明**: ユーザー独自の食品データ作成
- **認証**: 必須
- **リクエスト**:
  ```json
  {
    "name": "自家製サラダ",
    "calories": 150,
    "category": "野菜"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "foodId": "550e8400-e29b-41d4-a716-446655440099",
      "name": "自家製サラダ",
      "calories": 150,
      "category": "野菜",
      "isCustom": true,
      "createdAt": "2023-05-22T14:30:00Z",
      "updatedAt": "2023-05-22T14:30:00Z"
    }
  }
  ```

#### 4.4.4 カスタム食品更新
- **エンドポイント**: `PUT /api/v1/foods/{foodId}`
- **説明**: ユーザー作成の食品データ更新
- **認証**: 必須
- **パスパラメータ**:
  - `foodId`: 食品ID
- **リクエスト**:
  ```json
  {
    "name": "自家製サラダ（ドレッシング抜き）",
    "calories": 120,
    "category": "野菜"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "foodId": "550e8400-e29b-41d4-a716-446655440099",
      "name": "自家製サラダ（ドレッシング抜き）",
      "calories": 120,
      "category": "野菜",
      "isCustom": true,
      "updatedAt": "2023-05-22T15:45:00Z"
    }
  }
  ```

#### 4.4.5 カスタム食品削除
- **エンドポイント**: `DELETE /api/v1/foods/{foodId}`
- **説明**: ユーザー作成の食品データ削除
- **認証**: 必須
- **パスパラメータ**:
  - `foodId`: 食品ID
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "message": "食品データが正常に削除されました"
    }
  }
  ```

### 4.5 食事記録API

#### 4.5.1 食事記録一覧取得
- **エンドポイント**: `GET /api/v1/food-entries`
- **説明**: 食事記録の一覧取得
- **認証**: 必須
- **クエリパラメータ**:
  - `startDate`: 開始日 (YYYY-MM-DD)
  - `endDate`: 終了日 (YYYY-MM-DD)
  - `mealType`: 食事タイプ (オプション)
  - `page`: ページ番号 (デフォルト: 1)
  - `limit`: 1ページあたりの件数 (デフォルト: 20)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "items": [
        {
          "entryId": "550e8400-e29b-41d4-a716-446655440101",
          "date": "2023-05-22",
          "mealType": "朝食",
          "food": {
            "foodId": "550e8400-e29b-41d4-a716-446655440002",
            "name": "食パン（6枚切り1枚）",
            "calories": 177
          },
          "quantity": 2,
          "calories": 354,
          "note": "バター付き"
        },
        {
          "entryId": "550e8400-e29b-41d4-a716-446655440102",
          "date": "2023-05-22",
          "mealType": "昼食",
          "food": {
            "foodId": "550e8400-e29b-41d4-a716-446655440001",
            "name": "ごはん（茶碗1杯）",
            "calories": 240
          },
          "quantity": 1,
          "calories": 240,
          "note": null
        }
      ],
      "total": 8,
      "page": 1,
      "limit": 20,
      "pages": 1
    }
  }
  ```

#### 4.5.2 日別食事記録取得
- **エンドポイント**: `GET /api/v1/food-entries/daily/{date}`
- **説明**: 特定日の食事記録取得
- **認証**: 必須
- **パスパラメータ**:
  - `date`: 日付 (YYYY-MM-DD)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "date": "2023-05-22",
      "totalCalories": 1850,
      "targetCalories": 2000,
      "entries": [
        {
          "entryId": "550e8400-e29b-41d4-a716-446655440101",
          "mealType": "朝食",
          "food": {
            "foodId": "550e8400-e29b-41d4-a716-446655440002",
            "name": "食パン（6枚切り1枚）",
            "calories": 177
          },
          "quantity": 2,
          "calories": 354,
          "note": "バター付き",
          "createdAt": "2023-05-22T07:30:00Z"
        },
        // 他の食事記録...
      ]
    }
  }
  ```

#### 4.5.3 食事記録作成
- **エンドポイント**: `POST /api/v1/food-entries`
- **説明**: 新規食事記録の作成
- **認証**: 必須
- **リクエスト**:
  ```json
  {
    "date": "2023-05-22",
    "foodId": "550e8400-e29b-41d4-a716-446655440001",
    "quantity": 1.5,
    "mealType": "夕食",
    "note": "少し多めに食べた"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "entryId": "550e8400-e29b-41d4-a716-446655440103",
      "date": "2023-05-22",
      "mealType": "夕食",
      "food": {
        "foodId": "550e8400-e29b-41d4-a716-446655440001",
        "name": "ごはん（茶碗1杯）",
        "calories": 240
      },
      "quantity": 1.5,
      "calories": 360,
      "note": "少し多めに食べた",
      "createdAt": "2023-05-22T19:15:00Z",
      "updatedAt": "2023-05-22T19:15:00Z"
    }
  }
  ```

#### 4.5.4 食事記録更新
- **エンドポイント**: `PUT /api/v1/food-entries/{entryId}`
- **説明**: 既存の食事記録の更新
- **認証**: 必須
- **パスパラメータ**:
  - `entryId`: 記録ID
- **リクエスト**:
  ```json
  {
    "quantity": 1.0,
    "note": "普通量に修正"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "entryId": "550e8400-e29b-41d4-a716-446655440103",
      "date": "2023-05-22",
      "mealType": "夕食",
      "food": {
        "foodId": "550e8400-e29b-41d4-a716-446655440001",
        "name": "ごはん（茶碗1杯）",
        "calories": 240
      },
      "quantity": 1.0,
      "calories": 240,
      "note": "普通量に修正",
      "updatedAt": "2023-05-22T19:30:00Z"
    }
  }
  ```

#### 4.5.5 食事記録削除
- **エンドポイント**: `DELETE /api/v1/food-entries/{entryId}`
- **説明**: 食事記録の削除
- **認証**: 必須
- **パスパラメータ**:
  - `entryId`: 記録ID
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "message": "食事記録が正常に削除されました"
    }
  }
  ```

### 4.6 体重記録API

#### 4.6.1 体重記録一覧取得
- **エンドポイント**: `GET /api/v1/weights`
- **説明**: 体重記録の一覧取得
- **認証**: 必須
- **クエリパラメータ**:
  - `startDate`: 開始日 (YYYY-MM-DD)
  - `endDate`: 終了日 (YYYY-MM-DD)
  - `page`: ページ番号 (デフォルト: 1)
  - `limit`: 1ページあたりの件数 (デフォルト: 31)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "items": [
        {
          "weightId": "550e8400-e29b-41d4-a716-446655440201",
          "date": "2023-05-22",
          "value": 72.5,
          "note": "朝食前",
          "createdAt": "2023-05-22T06:30:00Z"
        },
        {
          "weightId": "550e8400-e29b-41d4-a716-446655440202",
          "date": "2023-05-21",
          "value": 72.8,
          "note": null,
          "createdAt": "2023-05-21T07:00:00Z"
        }
      ],
      "total": 30,
      "page": 1,
      "limit": 31,
      "pages": 1
    }
  }
  ```

#### 4.6.2 特定日の体重記録取得
- **エンドポイント**: `GET /api/v1/weights/{date}`
- **説明**: 特定日の体重記録取得
- **認証**: 必須
- **パスパラメータ**:
  - `date`: 日付 (YYYY-MM-DD)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "weightId": "550e8400-e29b-41d4-a716-446655440201",
      "date": "2023-05-22",
      "value": 72.5,
      "note": "朝食前",
      "createdAt": "2023-05-22T06:30:00Z",
      "updatedAt": "2023-05-22T06:30:00Z"
    }
  }
  ```

#### 4.6.3 体重記録作成/更新
- **エンドポイント**: `PUT /api/v1/weights/{date}`
- **説明**: 特定日の体重記録作成または更新（同じ日に複数の記録を許可しない）
- **認証**: 必須
- **パスパラメータ**:
  - `date`: 日付 (YYYY-MM-DD)
- **リクエスト**:
  ```json
  {
    "value": 72.3,
    "note": "夜、入浴後"
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "weightId": "550e8400-e29b-41d4-a716-446655440201",
      "date": "2023-05-22",
      "value": 72.3,
      "note": "夜、入浴後",
      "createdAt": "2023-05-22T06:30:00Z",
      "updatedAt": "2023-05-22T21:45:00Z"
    }
  }
  ```

#### 4.6.4 体重記録削除
- **エンドポイント**: `DELETE /api/v1/weights/{date}`
- **説明**: 特定日の体重記録削除
- **認証**: 必須
- **パスパラメータ**:
  - `date`: 日付 (YYYY-MM-DD)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "message": "体重記録が正常に削除されました"
    }
  }
  ```

### 4.7 統計・分析API

#### 4.7.1 カロリー摂取統計取得
- **エンドポイント**: `GET /api/v1/stats/calories`
- **説明**: 期間別のカロリー摂取統計取得
- **認証**: 必須
- **クエリパラメータ**:
  - `startDate`: 開始日 (YYYY-MM-DD)
  - `endDate`: 終了日 (YYYY-MM-DD)
  - `groupBy`: グループ化単位 (day/week/month, デフォルト: day)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "period": {
        "startDate": "2023-05-01",
        "endDate": "2023-05-31"
      },
      "summary": {
        "totalCalories": 62450,
        "averageCalories": 2015,
        "minCalories": 1650,
        "maxCalories": 2450
      },
      "items": [
        {
          "date": "2023-05-01",
          "calories": 1950,
          "target": 2000
        },
        {
          "date": "2023-05-02",
          "calories": 2100,
          "target": 2000
        }
        // 他の日付...
      ]
    }
  }
  ```

#### 4.7.2 体重推移統計取得
- **エンドポイント**: `GET /api/v1/stats/weights`
- **説明**: 期間別の体重推移統計取得
- **認証**: 必須
- **クエリパラメータ**:
  - `startDate`: 開始日 (YYYY-MM-DD)
  - `endDate`: 終了日 (YYYY-MM-DD)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "period": {
        "startDate": "2023-05-01",
        "endDate": "2023-05-31"
      },
      "summary": {
        "startWeight": 74.2,
        "endWeight": 72.3,
        "change": -1.9,
        "averageWeight": 73.1,
        "minWeight": 72.1,
        "maxWeight": 74.5
      },
      "items": [
        {
          "date": "2023-05-01",
          "value": 74.2
        },
        {
          "date": "2023-05-02",
          "value": 74.0
        }
        // 他の日付...
      ]
    }
  }
  ```

#### 4.7.3 カロリー・体重相関分析
- **エンドポイント**: `GET /api/v1/stats/correlation`
- **説明**: カロリー摂取と体重変化の相関分析
- **認証**: 必須
- **クエリパラメータ**:
  - `startDate`: 開始日 (YYYY-MM-DD)
  - `endDate`: 終了日 (YYYY-MM-DD)
  - `smoothing`: 平滑化期間 (日数, デフォルト: 7)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "period": {
        "startDate": "2023-05-01",
        "endDate": "2023-05-31"
      },
      "correlation": {
        "coefficient": 0.72,
        "significance": "strong"
      },
      "items": [
        {
          "date": "2023-05-01",
          "calories": 1950,
          "weight": 74.2,
          "caloriesSmoothed": 2050,
          "weightSmoothed": 74.1
        },
        // 他の日付...
      ]
    }
  }
  ```

### 4.8 データ管理API

#### 4.8.1 データエクスポート
- **エンドポイント**: `GET /api/v1/data/export`
- **説明**: ユーザーデータのエクスポート
- **認証**: 必須
- **クエリパラメータ**:
  - `format`: 出力形式 (json/csv, デフォルト: json)
  - `startDate`: 開始日 (YYYY-MM-DD, オプション)
  - `endDate`: 終了日 (YYYY-MM-DD, オプション)
  - `includeProfile`: プロフィール情報を含める (true/false, デフォルト: true)
  - `includeFoods`: カスタム食品情報を含める (true/false, デフォルト: true)
  - `includeFoodEntries`: 食事記録を含める (true/false, デフォルト: true)
  - `includeWeights`: 体重記録を含める (true/false, デフォルト: true)
- **レスポンス**: ファイルダウンロード

#### 4.8.2 データインポート
- **エンドポイント**: `POST /api/v1/data/import`
- **説明**: ユーザーデータのインポート
- **認証**: 必須
- **リクエスト**: マルチパートフォームデータ
  - `file`: インポートファイル (JSON/CSV)
  - `strategy`: 重複時の戦略 (skip/overwrite/merge, デフォルト: skip)
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "imported": {
        "profile": true,
        "foods": 12,
        "foodEntries": 145,
        "weights": 30
      },
      "skipped": {
        "foods": 2,
        "foodEntries": 5,
        "weights": 0
      },
      "errors": []
    }
  }
  ```

#### 4.8.3 データ同期
- **エンドポイント**: `POST /api/v1/data/sync`
- **説明**: クライアントとサーバー間のデータ同期
- **認証**: 必須
- **リクエスト**:
  ```json
  {
    "lastSyncTimestamp": "2023-05-20T15:30:00Z",
    "changes": {
      "foods": [
        {
          "action": "create",
          "data": { ... }
        },
        {
          "action": "update",
          "id": "550e8400-e29b-41d4-a716-446655440099",
          "data": { ... }
        }
      ],
      "foodEntries": [ ... ],
      "weights": [ ... ]
    }
  }
  ```
- **レスポンス**:
  ```json
  {
    "status": "success",
    "data": {
      "syncTimestamp": "2023-05-22T10:15:00Z",
      "changes": {
        "foods": [ ... ],
        "foodEntries": [ ... ],
        "weights": [ ... ]
      },
      "conflicts": [ ... ]
    }
  }
  ```

## 5. 実装詳細

### 5.1 ディレクトリ構造

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # アプリケーションエントリーポイント
│   ├── core/                   # コア機能
│   │   ├── __init__.py
│   │   ├── config.py           # 設定管理
│   │   ├── security.py         # 認証・認可
│   │   └── exceptions.py       # 例外定義
│   ├── api/                    # APIエンドポイント
│   │   ├── __init__.py
│   │   ├── deps.py             # 依存性注入
│   │   ├── v1/                 # APIバージョン1
│   │   │   ├── __init__.py
│   │   │   ├── endpoints/      # エンドポイント実装
│   │   │   │   ├── __init__.py
│   │   │   │   ├── auth.py
│   │   │   │   ├── users.py
│   │   │   │   ├── foods.py
│   │   │   │   ├── food_entries.py
│   │   │   │   ├── weights.py
│   │   │   │   ├── stats.py
│   │   │   │   └── data.py
│   │   │   └── router.py       # ルーティング
│   ├── models/                 # データモデル
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── food.py
│   │   ├── food_entry.py
│   │   └── weight.py
│   ├── schemas/                # Pydanticスキーマ
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── food.py
│   │   ├── food_entry.py
│   │   ├── weight.py
│   │   └── stats.py
│   ├── crud/                   # CRUDオペレーション
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── user.py
│   │   ├── food.py
│   │   ├── food_entry.py
│   │   └── weight.py
│   ├── services/               # ビジネスロジック
│   │   ├── __init__.py
│   │   ├── auth_service.py
│   │   ├── user_service.py
│   │   ├── food_service.py
│   │   ├── food_entry_service.py
│   │   ├── weight_service.py
│   │   ├── stats_service.py
│   │   ├── export_service.py
│   │   ├── import_service.py
│   │   └── sync_service.py
│   └── utils/                  # ユーティリティ
│       ├── __init__.py
│       ├── date_utils.py
│       └── validation.py
├── alembic/                    # マイグレーション
│   ├── versions/
│   ├── env.py
│   └── alembic.ini
├── tests/                      # テスト
│   ├── __init__.py
│   ├── conftest.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── test_auth.py
│   │   ├── test_users.py
│   │   └── ...
│   ├── services/
│   │   ├── __init__.py
│   │   ├── test_auth_service.py
│   │   └── ...
│   └── utils/
│       ├── __init__.py
│       └── test_date_utils.py
├── pyproject.toml              # 依存関係管理
├── Dockerfile                  # コンテナ化
├── docker-compose.yml          # 開発環境
└── README.md                   # ドキュメント
```

### 5.2 主要コンポーネント実装

#### 5.2.1 FastAPI アプリケーション設定

```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.router import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="カロリー管理アプリのバックエンドAPI",
    version="1.0.0",
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORSミドルウェア設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# APIルーターの登録
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {"message": "カロリー管理アプリAPI"}
```

#### 5.2.2 認証実装

```python
# app/core/security.py
from datetime import datetime, timedelta
from typing import Any, Optional

from jose import jwt
from passlib.context import CryptContext

from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(subject: str, expires_delta: Optional[timedelta] = None) -> str:
    """JWTアクセストークンの生成"""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    to_encode = {"exp": expire, "sub": subject}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """パスワード検証"""
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """パスワードハッシュ化"""
    return pwd_context.hash(password)
```

#### 5.2.3 データモデル実装例

```python
# app/models/food_entry.py
from sqlalchemy import Column, Integer, String, Float, ForeignKey, Date, Text, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.db.base_class import Base

class FoodEntry(Base):
    __tablename__ = "food_entries"

    entry_id = Column(String(36), primary_key=True, index=True)
    user_id = Column(String(36), ForeignKey("users.user_id"), nullable=False)
    food_id = Column(String(36), ForeignKey("foods.food_id"), nullable=False)
    date = Column(Date, nullable=False, index=True)
    quantity = Column(Float, nullable=False, default=1.0)
    meal_type = Column(String(20), nullable=False)
    calories = Column(Integer, nullable=False)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # リレーションシップ
    user = relationship("User", back_populates="food_entries")
    food = relationship("Food", back_populates="entries")
```

#### 5.2.4 スキーマ実装例

```python
# app/schemas/food_entry.py
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field

class FoodBase(BaseModel):
    food_id: str
    name: str
    calories: int

class FoodEntryBase(BaseModel):
    date: date
    food_id: str
    quantity: float = Field(1.0, ge=0.1)
    meal_type: str
    note: Optional[str] = None

class FoodEntryCreate(FoodEntryBase):
    pass

class FoodEntryUpdate(BaseModel):
    quantity: Optional[float] = Field(None, ge=0.1)
    meal_type: Optional[str] = None
    note: Optional[str] = None

class FoodEntryInDB(FoodEntryBase):
    entry_id: str
    user_id: str
    calories: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class FoodEntryResponse(BaseModel):
    entry_id: str
    date: date
    meal_type: str
    food: FoodBase
    quantity: float
    calories: int
    note: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        orm_mode = True
```

#### 5.2.5 CRUD操作実装例

```python
# app/crud/food_entry.py
from datetime import date
from typing import List, Optional
from uuid import uuid4

from sqlalchemy.orm import Session

from app.models.food_entry import FoodEntry
from app.schemas.food_entry import FoodEntryCreate, FoodEntryUpdate

def get_by_id(db: Session, entry_id: str) -> Optional[FoodEntry]:
    """IDによる食事記録取得"""
    return db.query(FoodEntry).filter(FoodEntry.entry_id == entry_id).first()

def get_by_user_and_date(db: Session, user_id: str, date: date) -> List[FoodEntry]:
    """ユーザーIDと日付による食事記録取得"""
    return db.query(FoodEntry).filter(
        FoodEntry.user_id == user_id,
        FoodEntry.date == date
    ).all()

def get_by_user_and_date_range(
    db: Session, user_id: str, start_date: date, end_date: date
) -> List[FoodEntry]:
    """ユーザーIDと日付範囲による食事記録取得"""
    return db.query(FoodEntry).filter(
        FoodEntry.user_id == user_id,
        FoodEntry.date >= start_date,
        FoodEntry.date <= end_date
    ).all()

def create(db: Session, obj_in: FoodEntryCreate, user_id: str, calories: int) -> FoodEntry:
    """食事記録作成"""
    entry_id = str(uuid4())
    db_obj = FoodEntry(
        entry_id=entry_id,
        user_id=user_id,
        food_id=obj_in.food_id,
        date=obj_in.date,
        quantity=obj_in.quantity,
        meal_type=obj_in.meal_type,
        calories=calories,
        note=obj_in.note
    )
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def update(db: Session, db_obj: FoodEntry, obj_in: FoodEntryUpdate, calories: Optional[int] = None) -> FoodEntry:
    """食事記録更新"""
    update_data = obj_in.dict(exclude_unset=True)
    if calories is not None:
        update_data["calories"] = calories
    
    for field, value in update_data.items():
        setattr(db_obj, field, value)
    
    db.add(db_obj)
    db.commit()
    db.refresh(db_obj)
    return db_obj

def delete(db: Session, db_obj: FoodEntry) -> None:
    """食事記録削除"""
    db.delete(db_obj)
    db.commit()
```

#### 5.2.6 サービス実装例

```python
# app/services/food_entry_service.py
from datetime import date
from typing import Dict, List, Optional

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.crud import food as crud_food
from app.crud import food_entry as crud_food_entry
from app.models.food_entry import FoodEntry
from app.schemas.food_entry import FoodEntryCreate, FoodEntryUpdate, FoodEntryResponse

class FoodEntryService:
    def __init__(self, db: Session = Depends(get_db)):
        self.db = db
    
    def calculate_calories(self, food_id: str, quantity: float) -> int:
        """食品IDと数量からカロリーを計算"""
        food = crud_food.get_by_id(self.db, food_id)
        if not food:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Food with ID {food_id} not found"
            )
        
        return round(food.calories * quantity)
    
    def get_daily_entries(self, user_id: str, date: date) -> List[FoodEntryResponse]:
        """特定日の食事記録一覧を取得"""
        entries = crud_food_entry.get_by_user_and_date(self.db, user_id, date)
        return [self._to_response(entry) for entry in entries]
    
    def get_daily_calories(self, user_id: str, date: date) -> int:
        """特定日の総カロリーを計算"""
        entries = crud_food_entry.get_by_user_and_date(self.db, user_id, date)
        return sum(entry.calories for entry in entries)
    
    def create_entry(self, user_id: str, entry_in: FoodEntryCreate) -> FoodEntryResponse:
        """食事記録を作成"""
        calories = self.calculate_calories(entry_in.food_id, entry_in.quantity)
        entry = crud_food_entry.create(self.db, entry_in, user_id, calories)
        return self._to_response(entry)
    
    def update_entry(self, user_id: str, entry_id: str, entry_in: FoodEntryUpdate) -> FoodEntryResponse:
        """食事記録を更新"""
        entry = crud_food_entry.get_by_id(self.db, entry_id)
        if not entry or entry.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food entry not found"
            )
        
        calories = None
        if entry_in.quantity is not None:
            calories = self.calculate_calories(entry.food_id, entry_in.quantity)
        
        updated_entry = crud_food_entry.update(self.db, entry, entry_in, calories)
        return self._to_response(updated_entry)
    
    def delete_entry(self, user_id: str, entry_id: str) -> Dict[str, str]:
        """食事記録を削除"""
        entry = crud_food_entry.get_by_id(self.db, entry_id)
        if not entry or entry.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food entry not found"
            )
        
        crud_food_entry.delete(self.db, entry)
        return {"message": "食事記録が正常に削除されました"}
    
    def _to_response(self, entry: FoodEntry) -> FoodEntryResponse:
        """モデルからレスポンススキーマへの変換"""
        food = crud_food.get_by_id(self.db, entry.food_id)
        return FoodEntryResponse(
            entry_id=entry.entry_id,
            date=entry.date,
            meal_type=entry.meal_type,
            food={
                "food_id": food.food_id,
                "name": food.name,
                "calories": food.calories
            },
            quantity=entry.quantity,
            calories=entry.calories,
            note=entry.note,
            created_at=entry.created_at,
            updated_at=entry.updated_at
        )
```

#### 5.2.7 APIエンドポイント実装例

```python
# app/api/v1/endpoints/food_entries.py
from datetime import date
from typing import List, Dict, Any

from fastapi import APIRouter, Depends, Query, Path, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.food_entry import FoodEntryCreate, FoodEntryUpdate, FoodEntryResponse
from app.services.food_entry_service import FoodEntryService

router = APIRouter()

@router.get("/", response_model=Dict[str, Any])
def get_food_entries(
    start_date: date = Query(..., description="開始日 (YYYY-MM-DD)"),
    end_date: date = Query(..., description="終了日 (YYYY-MM-DD)"),
    meal_type: str = Query(None, description="食事タイプでフィルタ"),
    page: int = Query(1, ge=1, description="ページ番号"),
    limit: int = Query(20, ge=1, le=100, description="1ページあたりの件数"),
    current_user: User = Depends(get_current_user),
    service: FoodEntryService = Depends()
):
    """食事記録の一覧を取得"""
    # 実装省略
    pass

@router.get("/daily/{date}", response_model=Dict[str, Any])
def get_daily_food_entries(
    date: date = Path(..., description="日付 (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    service: FoodEntryService = Depends()
):
    """特定日の食事記録を取得"""
    entries = service.get_daily_entries(current_user.user_id, date)
    total_calories = service.get_daily_calories(current_user.user_id, date)
    
    return {
        "status": "success",
        "data": {
            "date": date,
            "totalCalories": total_calories,
            "targetCalories": current_user.target_calories or 2000,
            "entries": entries
        }
    }

@router.post("/", response_model=Dict[str, Any])
def create_food_entry(
    entry_in: FoodEntryCreate,
    current_user: User = Depends(get_current_user),
    service: FoodEntryService = Depends()
):
    """新規食事記録を作成"""
    entry = service.create_entry(current_user.user_id, entry_in)
    
    return {
        "status": "success",
        "data": entry
    }

@router.put("/{entry_id}", response_model=Dict[str, Any])
def update_food_entry(
    entry_id: str = Path(..., description="記録ID"),
    entry_in: FoodEntryUpdate = None,
    current_user: User = Depends(get_current_user),
    service: FoodEntryService = Depends()
):
    """食事記録を更新"""
    entry = service.update_entry(current_user.user_id, entry_id, entry_in)
    
    return {
        "status": "success",
        "data": entry
    }

@router.delete("/{entry_id}", response_model=Dict[str, Any])
def delete_food_entry(
    entry_id: str = Path(..., description="記録ID"),
    current_user: User = Depends(get_current_user),
    service: FoodEntryService = Depends()
):
    """食事記録を削除"""
    result = service.delete_entry(current_user.user_id, entry_id)
    
    return {
        "status": "success",
        "data": result
    }
```

## 6. セキュリティ実装

### 6.1 認証・認可

#### 6.1.1 JWT認証フロー
1. ユーザーがログイン情報を送信
2. サーバーが認証情報を検証
3. 認証成功時、アクセストークンとリフレッシュトークンを発行
4. クライアントは以降のリクエストにアクセストークンを付与
5. トークン期限切れ時はリフレッシュトークンで更新

#### 6.1.2 認証ミドルウェア実装

```python
# app/api/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import ALGORITHM
from app.crud import user as crud_user
from app.db.session import get_db
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> User:
    """現在のユーザーを取得"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="認証情報が無効です",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = crud_user.get_by_id(db, user_id)
    if user is None:
        raise credentials_exception
    
    return user
```

### 6.2 データ保護

#### 6.2.1 パスワード保護
- bcryptによるパスワードハッシュ化
- ソルト自動生成
- 適切なワークファクター設定

#### 6.2.2 データ暗号化
- 保存データの暗号化（AES-256）
- 転送中のデータ保護（TLS）
- 機密情報のマスキング

#### 6.2.3 セキュアなデータ同期
- 差分同期による最小データ転送
- コンフリクト解決アルゴリズム
- 同期トークンによる認証

### 6.3 セキュリティヘッダー

```python
# app/main.py
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware

# 本番環境のみ適用
if settings.ENVIRONMENT == "production":
    # HTTPSリダイレクト
    app.add_middleware(HTTPSRedirectMiddleware)
    
    # 信頼できるホストのみ許可
    app.add_middleware(
        TrustedHostMiddleware, allowed_hosts=settings.ALLOWED_HOSTS
    )

# セキュリティヘッダー
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

## 7. パフォーマンス最適化

### 7.1 データベース最適化

#### 7.1.1 インデックス戦略
- 頻繁にクエリされるカラムにインデックス作成
  - ユーザーID
  - 日付
  - 食品名
  - ユーザーID + 日付の複合インデックス
- 複合インデックスの活用
- インデックスの定期的な分析と最適化

#### 7.1.2 クエリ最適化
- N+1問題の回避（Joinedロード）
  ```python
  # 非効率なクエリ（N+1問題）
  entries = db.query(FoodEntry).filter(FoodEntry.user_id == user_id).all()
  for entry in entries:
      food = db.query(Food).filter(Food.food_id == entry.food_id).first()
      # 処理...
  
  # 最適化されたクエリ（Joinedロード）
  entries = db.query(FoodEntry).options(
      joinedload(FoodEntry.food)
  ).filter(FoodEntry.user_id == user_id).all()
  for entry in entries:
      food = entry.food
      # 処理...
  ```
- 必要なカラムのみ選択
  ```python
  # 全カラム取得
  users = db.query(User).all()
  
  # 必要なカラムのみ取得
  users = db.query(User.user_id, User.name, User.target_calories).all()
  ```
- ページネーションの実装
  ```python
  def get_paginated_items(db, model, page=1, limit=20, **filters):
      skip = (page - 1) * limit
      return db.query(model).filter_by(**filters).offset(skip).limit(limit).all()
  ```

#### 7.1.3 コネクションプーリング
- データベース接続の再利用
- 適切なプールサイズ設定
  ```python
  # app/db/session.py
  from sqlalchemy import create_engine
  from sqlalchemy.orm import sessionmaker
  
  from app.core.config import settings
  
  engine = create_engine(
      settings.DATABASE_URI,
      pool_size=settings.DB_POOL_SIZE,
      max_overflow=settings.DB_MAX_OVERFLOW,
      pool_timeout=settings.DB_POOL_TIMEOUT,
      pool_recycle=settings.DB_POOL_RECYCLE
  )
  
  SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
  
  def get_db():
      db = SessionLocal()
      try:
          yield db
      finally:
          db.close()
  ```
- コネクションタイムアウト管理

### 7.2 キャッシュ戦略

#### 7.2.1 アプリケーションキャッシュ
- 頻繁にアクセスされるデータのメモリキャッシュ
  ```python
  # app/core/cache.py
  from functools import lru_cache
  
  @lru_cache(maxsize=100)
  def get_common_food_items():
      # 頻繁に使用される食品データの取得
      pass
  ```
- TTL（Time-to-Live）設定
- キャッシュ無効化戦略

#### 7.2.2 レスポンスキャッシュ
- 静的レスポンスのキャッシュ
- ETags実装
  ```python
  # app/api/v1/endpoints/foods.py
  from fastapi import Response
  import hashlib
  
  @router.get("/common")
  def get_common_foods(response: Response):
      foods = get_common_food_items()
      # レスポンスのハッシュ値を計算
      content_hash = hashlib.md5(str(foods).encode()).hexdigest()
      response.headers["ETag"] = f'"{content_hash}"'
      return foods
  ```
- 条件付きリクエスト対応

### 7.3 非同期処理

#### 7.3.1 非同期APIエンドポイント
- FastAPIの非同期サポート活用
  ```python
  @router.get("/stats/calories")
  async def get_calorie_stats(
      start_date: date,
      end_date: date,
      current_user: User = Depends(get_current_user)
  ):
      # 非同期処理
      stats = await calculate_calorie_stats(current_user.user_id, start_date, end_date)
      return {"status": "success", "data": stats}
  ```
- 長時間実行タスクの非同期処理
- 並列リクエスト処理

#### 7.3.2 バックグラウンドタスク
- データ同期の非同期実行
  ```python
  from fastapi.background import BackgroundTasks
  
  @router.post("/data/sync")
  def sync_data(
      sync_data: SyncRequest,
      background_tasks: BackgroundTasks,
      current_user: User = Depends(get_current_user)
  ):
      # 即時レスポンス
      background_tasks.add_task(
          process_sync_data, current_user.user_id, sync_data
      )
      return {"status": "success", "message": "同期処理を開始しました"}
  ```
- 統計計算のバックグラウンド処理
- 定期的なデータクリーンアップ

## 8. テスト戦略

### 8.1 テスト種別

#### 8.1.1 単体テスト
- モデル、スキーマ、ユーティリティ関数のテスト
- モックを使用した依存関係の分離
- Pytestによるテスト実行

```python
# tests/services/test_food_entry_service.py
import pytest
from unittest.mock import MagicMock
from datetime import date

from app.services.food_entry_service import FoodEntryService
from app.schemas.food_entry import FoodEntryCreate

def test_calculate_calories():
    # モックの設定
    mock_db = MagicMock()
    mock_food = MagicMock()
    mock_food.calories = 200
    mock_db.query().filter().first.return_value = mock_food
    
    # サービスのインスタンス化
    service = FoodEntryService(db=mock_db)
    
    # テスト実行
    result = service.calculate_calories("food-id", 1.5)
    
    # 検証
    assert result == 300  # 200 * 1.5
```

#### 8.1.2 統合テスト
- APIエンドポイントのテスト
- 実際のデータベースとの連携テスト
- テスト用データベースの使用

```python
# tests/api/test_food_entries.py
from fastapi.testclient import TestClient
from datetime import date

from app.main import app
from tests.utils.auth import get_test_token

client = TestClient(app)

def test_create_food_entry():
    # テストユーザーのトークン取得
    token = get_test_token()
    
    # テストデータ
    test_entry = {
        "date": str(date.today()),
        "foodId": "test-food-id",
        "quantity": 1.0,
        "mealType": "朝食",
        "note": "テスト"
    }
    
    # APIリクエスト
    response = client.post(
        "/api/v1/food-entries",
        json=test_entry,
        headers={"Authorization": f"Bearer {token}"}
    )
    
    # 検証
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["data"]["mealType"] == "朝食"
    assert data["data"]["quantity"] == 1.0
```

#### 8.1.3 エンドツーエンドテスト
- ユーザーフローの検証
- フロントエンドとバックエンドの連携テスト
- SeleniumやPlaywrightを使用したUIテスト

### 8.2 テストカバレッジ

#### 8.2.1 カバレッジ目標
- コードカバレッジ: 80%以上
- 重要なビジネスロジック: 95%以上
- APIエンドポイント: 100%

#### 8.2.2 カバレッジレポート
- Pytestとcoverageを使用したレポート生成
- CIパイプラインでのカバレッジチェック

```bash
# カバレッジレポート生成コマンド
pytest --cov=app --cov-report=xml --cov-report=term
```

### 8.3 テスト自動化

#### 8.3.1 CI/CDパイプライン
- プルリクエスト時の自動テスト実行
- マージ前のテスト合格要件
- 定期的な回帰テスト

#### 8.3.2 テストデータ管理
- フィクスチャーの使用
- テストデータファクトリー
- テスト環境のリセット

```python
# tests/conftest.py
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.db.session import get_db
from app.main import app

@pytest.fixture(scope="session")
def db_engine():
    engine = create_engine("sqlite:///./test.db", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)

@pytest.fixture(scope="function")
def db_session(db_engine):
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=db_engine)
    session = SessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()

@pytest.fixture(scope="function")
def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
```

## 9. デプロイメント戦略

### 9.1 環境構成

#### 9.1.1 開発環境
- ローカル開発環境
- SQLiteデータベース
- ホットリロード
- デバッグモード有効

#### 9.1.2 テスト環境
- CI/CD環境
- テスト用PostgreSQLデータベース
- テストスイート実行

#### 9.1.3 ステージング環境
- 本番と同等の構成
- テストデータ
- 機能検証

#### 9.1.4 本番環境
- 高可用性構成
- PostgreSQLデータベース
- CDNキャッシュ
- 監視・アラート

### 9.2 コンテナ化

#### 9.2.1 Dockerコンテナ
- アプリケーションコンテナ
- データベースコンテナ
- キャッシュコンテナ

```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY ./requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir --upgrade -r /app/requirements.txt

COPY ./app /app/app
COPY ./alembic /app/alembic
COPY ./alembic.ini /app/alembic.ini

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### 9.2.2 Kubernetes構成
- デプロイメント
- サービス
- イングレス
- シークレット管理

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: calorie-tracker-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: calorie-tracker-api
  template:
    metadata:
      labels:
        app: calorie-tracker-api
    spec:
      containers:
      - name: api
        image: calorie-tracker-api:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URI
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: uri
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "100m"
            memory: "256Mi"
```

### 9.3 CI/CDパイプライン

#### 9.3.1 継続的インテグレーション
- コードリント
- 単体テスト
- 統合テスト
- セキュリティスキャン

#### 9.3.2 継続的デリバリー
- 自動ビルド
- イメージタグ付け
- レジストリへのプッシュ
- ステージング環境へのデプロイ

#### 9.3.3 継続的デプロイメント
- 本番環境への自動デプロイ
- ブルー/グリーンデプロイメント
- カナリアリリース
- ロールバック機能

### 9.4 監視・運用

#### 9.4.1 ロギング
- 構造化ログ
- ログ集約
- ログ分析

```python
# app/core/logging.py
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_record = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        if hasattr(record, "request_id"):
            log_record["request_id"] = record.request_id
        
        if record.exc_info:
            log_record["exception"] = self.formatException(record.exc_info)
        
        return json.dumps(log_record)

def setup_logging():
    logger = logging.getLogger("app")
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    return logger
```

#### 9.4.2 メトリクス
- アプリケーションメトリクス
- インフラメトリクス
- ビジネスメトリクス

```python
# app/core/metrics.py
from prometheus_client import Counter, Histogram, start_http_server

# リクエストカウンター
REQUEST_COUNT = Counter(
    "app_request_count",
    "Application Request Count",
    ["method", "endpoint", "status"]
)

# レスポンス時間ヒストグラム
REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Application Request Latency",
    ["method", "endpoint"]
)

def init_metrics(port=8001):
    start_http_server(port)
```

#### 9.4.3 アラート
- 異常検知
- エスカレーションポリシー
- オンコール対応

## 10. 結論

### 10.1 設計のまとめ

本設計書では、カロリー管理アプリ「ずぼらカロリー」のバックエンドシステムの詳細設計を定義した。主な特徴は以下の通りである：

1. **ユーザー中心設計**：
   - 簡単な入力操作
   - 直感的なAPI設計
   - ユーザーデータの所有権尊重

2. **柔軟なデータ管理**：
   - ローカルファーストアプローチ
   - オプショナルなクラウド同期
   - 包括的なデータインポート/エクスポート

3. **堅牢なアーキテクチャ**：
   - レイヤー化されたアーキテクチャ
   - 明確な関心の分離
   - スケーラブルな設計

4. **セキュリティとプライバシー**：
   - JWTベースの認証
   - データ暗号化
   - 最小権限の原則

### 10.2 実装フェーズへの移行

本設計書に基づき、以下のステップで実装を進めることを推奨する：

1. **フェーズ1**：基本機能の実装
   - ユーザー認証
   - 食品データベース
   - 食事記録
   - 体重記録

2. **フェーズ2**：拡張機能の実装
   - 統計・分析
   - データ同期
   - インポート/エクスポート

3. **フェーズ3**：最適化と拡張
   - パフォーマンス最適化
   - UI/UX改善
   - 追加機能の実装

### 10.3 今後の展望

本システムは以下の方向性での拡張が考えられる：

1. **機能拡張**：
   - 栄養素詳細トラッキング
   - 食事写真記録
   - AIによる食品認識

2. **連携拡張**：
   - 活動量計との連携
   - 健康管理アプリとの連携
   - ソーシャル機能

3. **プラットフォーム拡張**：
   - ウェブアプリケーション
   - スマートウォッチアプリ
   - 音声アシスタント連携

本設計書が「ずぼらでもカロリー管理できる」というコンセプトを実現し、ユーザーの健康的な食生活をサポートするシステム構築の基盤となることを期待する。
