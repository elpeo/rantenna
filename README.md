# rAntenna
rAntenna は Ruby で記述された Web サイトの更新時刻取得エージェントです。 以下の特徴があります。

* Ruby で書かれている。
* 出力形式が RDF (HTML 出力も対応)

## ダウンロード
リリース版は以下からダウンロード可能です。

**最新版**

* https://github.com/downloads/elpeo/rantenna/rantenna-0.0.6.tar.gz

**安定版**

* https://github.com/downloads/elpeo/rantenna/rantenna-0.0.5.tar.gz
* https://github.com/downloads/elpeo/rantenna/rantenna-0.0.4.tar.gz
* https://github.com/downloads/elpeo/rantenna/rantenna-0.0.3.tar.gz

プログラム本体の他に、

* Ruby1.6.7 以降
* [uconv](http://raa.ruby-lang.org/list.rhtml?name=uconv) (Ruby1.8.1 以前で UTF-8 で出力する場合)
* [ruby-zlib](http://raa.ruby-lang.org/list.rhtml?name=ruby-zlib) (Ruby1.6 で input_lirs.rb, output_lirs.rb を使う場合)

が必要です。

## 動作例
http://elpeo.jp/antenna/ で rAntenna を利用した更新時刻取得サイトを運用しています。

## 設定
### インストール

rAntenna は Ruby で書かれていますので、 まず Ruby がインストールされているか確認します。 インストールされてなかった場合はまず Ruby をインストールしてください。

次にダウンロードした rAntenna を適当な場所で以下のように解凍します。

    $ tar xvzf rantenna.tar.gz

解凍が完了すると、rantenna と言うディレクトリができています。 このディレクトリを /var/www/html/rantenna 等、 Web サーバーの公開ディレクトリにコピーすればインストールは完了です。

### .htaccess の設定
配布ファイルの中に dot.htaccess というファイルが同梱されていますので、 こちらを .htaccess にコピーします。

### antenna.conf の設定
rAntenna の設定ファイルは antenna.conf です。 配布ファイルの中には antenna.conf.sample というサンプル設定ファイルが 同梱されていますので、こちらを antenna.conf にコピーし、 必要な変更します。 必須項目は以下のとおりです。

```
@title       アンテナのタイトルを入れてください。
@copyright   Copyright を入れてください。
@antenna_url アンテナのURLを入れてください。
@rdf_url     出力されるRDFファイルのURLを入れてください。
@urls        巡回するURLを入れてください。
             形式は、
             タイトル, 作者, URL, 巡回URL
             です。巡回URLが無い場合はURLを使います。
```

以下の項目は任意で設定してください。

```
@filters     フィルタを入れてください。
@rdf_path    出力されるRDFファイル名を入れてください。
             絶対パスも使用できます。
@link_format URLからリンクを作成するフォーマットを指定してください。
             詳しい記法は antenna.conf.sample を参照ください。
```

@filters の設定方法については、フィルタをご参照ください。

@link_format で go.rb を使う場合の記述方法については、 [go.rb](http://elpeo.jp/wiki/?go.rb) をご参照ください。

## crontab の設定
rAntenna では update.rb というコマンドを実行したときに Web サイトの更新時刻を取得します。

定期的に更新時刻を取得する場合は cron を使い、 定期的に update.rb が実行されるようにします。

update.rb を実行する際の引数として、conf ファイルのパスを１つまたは複数指定できます。引数を指定しない場合は、update.rb と同じディレクトリにある antenna.conf というファイルを使用します。

### 拡張
この他の機能拡張・利用法に関しては [rAntenna plugin](http://elpeo.jp/wiki/?rAntenna+plugin) を参照ください。

* LIRS 入力
* HTML 出力
* LIRS 出力

などの話題を扱っています。
