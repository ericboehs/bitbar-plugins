# My Bitbar Plugins

## Circle CI
```
sudo /usr/bin/gem install bundler
cp .env.example .env
vi .env # Add your config vars
ln -s ~/Code/bitbar-plugins/.env ~/Documents/BitBar/.env
```

```
ln -s ~/Code/bitbar-plugins/circleci.rb ~/Documents/BitBar/circleci.30s.rb
ln -s ~/Code/bitbar-plugins/heroku.rb ~/Documents/BitBar/heroku.60s.rb
```
