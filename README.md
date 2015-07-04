#vim-sqlfix

[![Build Status](https://travis-ci.org/KazuakiM/vim-sqlfix.svg)](https://travis-ci.org/KazuakiM/vim-sqlfix)

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
