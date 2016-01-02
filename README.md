#vim-sqlfix

[![](https://img.shields.io/travis/KazuakiM/vim-sqlfix.svg)](https://travis-ci.org/KazuakiM/vim-sqlfix)
[![Build status](https://ci.appveyor.com/api/projects/status/lte1vdem9lmsyjo3/branch/master?svg=true)](https://ci.appveyor.com/project/KazuakiM/vim-sqlfix/branch/master)
[![](https://img.shields.io/github/issues/KazuakiM/vim-sqlfix.svg)](https://github.com/KazuakiM/vim-sqlfix/issues)
[![](https://img.shields.io/badge/doc-%3Ah%20sqlfix.txt-blue.svg)](doc/sqlfix.txt)
[![](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This Vim plugin is SQL pretty print.  
vim-sqlfix's goal is support FrameWork application log format.

##Support FrameWork
* [Yii](http://www.yiiframework.com/)
* [Ruby on Rails](http://rubyonrails.org/)

##Usage
### Normal mode

The last selected text in visual mode is formatted at SQL.
```vim
:Sqlfix
```

### Visual mode

Now selected text in visual mode is formatted at SQL.
```vim
:'<,'>Sqlfix
```

##Image

Normal

![Normal](http://kazuakim.github.io/img/vim-sqlfix001.gif)

Ruby on Rails&Yii

![Ruby on Rails&Yii](http://kazuakim.github.io/img/vim-sqlfix002.gif)

##Author

[KazuakiM](https://github.com/KazuakiM/)

##License

This software is released under the MIT License, see LICENSE.
