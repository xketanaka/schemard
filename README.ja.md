# SchemaRD

## 概要

SchemaRD は、Railsアプリケーションで利用する schema.rb を元にER図を生成するツールです。  
生成されたER図は、Webブラウザで閲覧することができます。

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

無作為に配置されたテーブルを任意の位置にレイアウトするには、図の左上の「テーブルの位置を編集」をチェックし、テーブルをドラッグします。

<img src="https://raw.githubusercontent.com/wiki/xketanaka/schemard/images/edit_layout_ja.png" width="700px" >

レイアウト調整が完了したら、「テーブル位置を編集」のチェックを外します。

### リレーション追加

デフォルトで生成されるER図には、テーブル同士のリレーション情報がありません。  
ER図にリレーションを追加するには、schema.rb とは別にリレーション情報を与える必要があります。  

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

3. 抽出したリレーション情報を読み込ませるには以下のように -f オプションを指定して実行します。
```
 $ schemard -f db/relation.metadata
```

4. 抽出したリレーションがER図に反映されています。Webブラウザで`http://localhost:10080`にアクセスすることで確認できます。

<img src="https://raw.githubusercontent.com/wiki/xketanaka/schemard/images/relation_added.png" width="700px" >

### 日本語化

デフォルトで生成されるER図では、テーブル名・カラム名は物理名で表示されます。  
テーブル名・カラム名を物理名以外の別名（論理名・日本語名）で表示する方法はいくつかありますが、  
ここでは、ActiveRecordのモデル名・属性名の翻訳辞書ファイルを利用する手順を説明します。

1. 以下の形式の翻訳辞書ファイルが`config/locale/ja.yml`に存在するものとします。
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

2. 以下のようにオプションで翻訳辞書ファイルを指定して実行します。
```
 $ schemard -f db/relation.metadata -f config/locale/ja.yml
```

3. Webブラウザで `http://localhost:10080` にアクセスするとテーブル名・カラム名が翻訳辞書ファイルに記述された表示名で表示されます。

## オプション

以下のコマンドラインオプションが指定可能です。

 * -i, --input-file ... `schema.rb`ファイルを指定します。デフォルトは`db/schema.rb`です。
 * -o, --output-file ... レイアウト情報を出力するファイルを指定します。デフォルトは schema.metadata です。
 * -f, -m, --metadata-file ... リレーション情報ファイル、翻訳辞書ファイルを指定します。デフォルトは`指定なし`です。
 * --rdoc, --rdoc-enabled ... `schema.rb`に記述しているrdocコメントからメタ情報を取得する場合に指定します。デフォルトは`指定なし`です。
 * --parse-db-comment-as ... マイグレーション情報のcommentオプションをどのように解釈するかを指定します。`name`,`ignore`が指定できます。`name`を指定するとcommentオプションで指定された値を論理名として解釈します。`ignore`を指定するとcommentオプションの値を無視します。デフォルトは`ignore`です。
 * -l, --log-output ... ログ出力先を指定します。`stdout`, `stderr`, `任意のファイル名`が指定できます。デフォルトは`stdout`です。
 * -s --silent --no-log-output ... ログ出力をしたくない場合に指定します。
 * -h, -host ... WebServerがListenするホスト名を指定します。デフォルトは`127.0.0.1`です。
 * -p, --port ... WebServerがListenするポートを指定します。デフォルトは`10080`です。

### サブコマンド

 * generate-relations ... Railsアプリケーションのモデル情報よりリレーション情報を抽出し、YAML形式で標準出力に出力します。`-d`オプションでRails.rootディレクトリを指定することができます(デフォルトはカレントディレクトリ)。

## 設定

コマンドラインオプションで指定する代わりに、設定ファイルでオプションを指定することができます。  
設定ファイルは`schemard`コマンド実行ディレクトリに`.schemard.config`という名前で作成します。  
以下のエントリを指定することができます。

 * input_file
 * output_file
 * metadata_files
 * rdoc_enabled
 * parse_db_comment_as
 * log_output
 * webserver_host
 * webserver_port

なお、設定ファイルとコマンドラインオプションの両方に指定がある場合、コマンドラインオプションが優先されます。
