Point Scripts
=============

これはなに？
------------

各種ポイントサイトからポイントを取得するためのPerlスクリプト群です。

現在、対応しているポイントとスクリプトの名前は次の通りです。

* 楽天スーパーポイント： rakuten_super_point.pl
* Tポイント： tpoint.pl
* ANAマイレージ： ana_mileage.pl

インストール方法
----------------

必要なcpanモジュールをインストール後、実行してください。

cpanモジュールのインストール例：

    cpanm Config::Pit WWW::Mechanize Web::Scraper

使い方
------

実行すると、取得したポイントを標準出力に出力します。

`-e` オプションを付けて実行すると、有効期限がある場合には有効期限も出力します。

ポイントをメール送信したい場合には、`mail`などを利用してください。

実行例：

    perl /path/to/ana_mileage.pl -e | nkf -j | mail -s "my ana mileage" user@example.com

謝辞
----

tpoint.plについては、tdtdsさんの[tpoint.rb](https://gist.github.com/297238)を参考にさせていただいています。

ライセンス
----------

Copyright (C) 2011 MATSUI Shinsuke <poppen.jp@gmail.com>

Released under the [MIT license](http://creativecommons.org/licenses/MIT/).
