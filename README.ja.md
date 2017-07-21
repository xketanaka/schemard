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
 $ schemard -i <path/to/schema.rb>
```

Webブラウザで`http://localhost:10080`にアクセスすると生成されたER図を参照できます。

## ER図の編集

### レイアウト調整

デフォルトで生成されるER図では、テーブルは無作為にレイアウトされています。  
図の左上の「テーブルの位置を編集」をチェックし、テーブルをドラッグすることで位置を調整することができます。

### リレーション追加

デフォルトで生成されるER図には、テーブル同士のリレーション情報がありません。  
ER図にリレーションを追加するには、別途リレーション情報を与える必要があります。  
リレーション情報を与える方法はいくつかありますが、ここではRailsアプリケーションのモデル情報を元にリレーション情報を追加する手順を説明します。

1. 以下のコマンドでリレーション情報を抽出します。ここでは`db/relatoin.metadata`に出力します。
```
 $ cd <Rails.root.dir>
 $ schemard gen-relation > db/relation.metadata
```
1. 抽出したリレーション情報を読み込ませるには以下のようにオプションを指定して実行します。
```
 $ schemard -i <path/to/schema.rb> -f db/relation.metadata
```
1. Webブラウザで`http://localhost:10080`にアクセスするとER図にリレーションが追加されて表示されます。

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

1. 以下のようにオプションで辞書ファイルを指定して実行します。
```
 $ schemard -i <path/to/schema.rb> -f db/relation.metadata -f config/locale/ja.yml
```

1. Webブラウザで `http://localhost:10080` にアクセスするとテーブル名・カラム名が辞書に従って変換されて表示されます。

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
