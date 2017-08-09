# SchemaRD

## 概要

SchemaRD は、Railsアプリケーションで利用する schema.rb を元にER図を生成するツールです。  
生成されたER図は、Webブラウザで閲覧およびレイアウト調整することができます。

## 使い方

インストール:
```
 $ gem install schemard
```

実行:
```
 $ schemard
```

Webブラウザで`http://localhost:10080`にアクセスすると生成されたER図を参照できます。

## ER図の編集

### レイアウト調整

デフォルトで生成されるER図では、テーブルは無作為にレイアウトされています。  
例として、RubyOnRailsチュートリアル( https://railstutorial.jp/ )のschema.rbより生成したER図を示します。

<img src="https://raw.githubusercontent.com/wiki/xketanaka/schemard/images/init_layout_ja.png" width="700px" >

図の左上の「テーブルの位置を編集」をチェックし、テーブルをドラッグすることでテーブルの配置場所を調整することができます。

<img src="https://raw.githubusercontent.com/wiki/xketanaka/schemard/images/edit_layout_ja.png" width="700px" >


### リレーション追加

デフォルトで生成されるER図には、テーブル同士のリレーション情報がありません。  
ER図にリレーションを追加するには、別途リレーション情報を与える必要があります。  

リレーション情報を与える方法はいくつかありますが、ここではRailsアプリケーションのモデル情報を元にリレーション情報を追加する手順を説明します。先程と同様に、RubyOnRailsチュートリアルのソースコードを用いて説明します。

1. 以下のコマンドでリレーション情報を抽出します。ここでは`db/relatoin.metadata`に出力します。
```
 $ cd <Rails.root.dir>
 $ schemard gen-relation > db/relation.metadata
```

2. `db/relatoin.metadata`には以下の内容が出力されます。
```
---
tables:
  users:
    has_many:
    - microposts
    - relationships
    - relationships
  relationships:
    belongs_to:
    - users
    - users
  microposts:
    belongs_to:
    - users
```

3. 抽出したリレーション情報を読み込ませるには以下のようにオプションを指定して実行します。
```
 $ schemard -f db/relation.metadata
```

4. Webブラウザで`http://localhost:10080`にアクセスするとER図にリレーションが追加されて表示されます。

<img src="https://raw.githubusercontent.com/wiki/xketanaka/schemard/images/relation_added.png" width="700px" >

### 日本語化

デフォルトで生成されるER図では、テーブル名・カラム名は物理名で表示されます。  
テーブル名・カラム名を物理名以外の別名（論理名や日本語名）で表示する方法はいくつかありますが、  
ここでは、ActiveRecordのモデル名・属性名の辞書ファイルを利用する手順を説明します。

1. 以下の形式の辞書ファイルが`config/locale/ja.yml`に存在するものとします。
```
ja:
  activerecord:
    models:
      <model_name>: <モデル名>

ja:
  activerecord:
    attributes:
      <model_name>:
        <column_name>: <column_name>
```

2. 以下のようにオプションで辞書ファイルを指定して実行します。
```
 $ schemard -f db/relation.metadata -f config/locale/ja.yml
```

3. Webブラウザで `http://localhost:10080` にアクセスするとテーブル名・カラム名が辞書ファイルに記述された表示名で表示されます。

## オプション

以下のコマンドラインオプションが指定可能です。

 * TODO

### サブコマンド

TODO

## 設定

コマンドラインオプションで指定する代わりに、設定ファイルでオプションを指定することができます。  
設定ファイルは`schemard`コマンド実行ディレクトリに`.schemard.config`という名前で作成します。  
以下のエントリを指定することができます。

* TODO

なお、設定ファイルとコマンドラインオプションの両方に指定がある場合、コマンドラインオプションが優先されます。
