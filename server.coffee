express = require 'express'
app     = express()

app.use '/Troxel/static', express.static __dirname + '/static'
app.use require('connect-assets') paths: ['coffee']
app.set 'views', 'views'
app.set 'view engine', 'jade'

app.get '/Troxel/', (req, res) -> res.render 'index', dev: true
app.get '*', (req, res) -> res.redirect '/Troxel/'

app.listen 3000