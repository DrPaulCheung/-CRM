# -CRM
会社の管理システム


MAC系统先安装环境
1 安装homebrew套件管理器 http://brew.sh/index_ja.html
2 homebrew安装rbenv    
  brew update
  brew upgrade rbenv ruby-build
  
3 安装ruby2.2.3或以上
  rbenv install 2.2.3
  rbenv global 2.2.3

4 安装mongodb数据库
  https://www.mongodb.com/jp下载安装
  配置到环境变量 export PATH=xxxxxx:$PATH    xxx为mongo目录
  echo 'export PATH=/USERS/bobo/Documents/mongodb/bin:$PATH'>>~/.bash_profile 
  
  下载git目录中的database里的文件 解压到做生意文件夹 如 /Users/xxx/Documents/Mongod/db
  启动数据库 mongod --dbpath /User/xxx/Documents/Mongod/db
  
5 安装服务器环境
  gem install sinatra 
  gem install mongo
  gem install json
  gem install bson_ext
  
6 启动服务器
  ruby App.rb -o 0.0.0.0 -p 任意端口号

浏览器中访问 ip地址:端口号 即可访问
  
  
windows下安装
  下载rubyinstaller以及DevKit http://rubyinstaller.org/
  官网下载mongodb数据库
  
  启动步骤同mac

附数据库可视化管理工具
  https://robomongo.org/
  
