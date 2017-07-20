# SchemaRD

## Overview

SchemaRD is a Entity Relationship Diagram Viewer for schema.rb which is used on Ruby On Rails.
You can browse Entity Relationship Diagram of your schema.rb, on your WebBrowser.

## HowToUse

Install:
```
 $ gem install schemard
```

And run:
```
 $ schemard -f <path/to/schema.rb>
```


Webブラウザで、http://localhost:14567 にアクセス。

### 説明

実行するとWebサーバが起動します。デフォルトでは14567ポートで待ち受けています。
WebサーバはSinatra(http://www.sinatrarb.com/)を利用しています。

### 指定可能なオプション

* -f ... データベース定義ファイルのパスを指定します。

### コマンド実行

````
 $ cd lib
 $ ruby schema_parser.rb
```

Webサーバを起動せずにHTMLだけ生成するには上記のように実行することができます。

----

ja:

## 概要

SchemaRD は RubyOnRails で使われる schema.rb ファイルに定義されたスキーマ情報をER図として参照する
