const express = require('express')
const Redis = require('ioredis')
const axios = require('axios')
const ejs = require('ejs')

const PORT = process.env.PORT || 3000
const REDIS_HOST = process.env.REDIS_HOST || 'redis'

const app = express()
app.set('views', 'views')
app.set('view engine', 'ejs')
app.use(express.static('public'))
app.use(express.json())

app.locals.version = require('./package.json').version

// console.log(process.env.NODE_ENV)
if (process.env.NODE_ENV == 'development') {
    const livereload = require('connect-livereload')
    app.use(livereload())
  }

const redis = new Redis({
    port: 6379,
    host: REDIS_HOST
})

app.get('/', async (req, res) => {
    try {
        const url = process.env.NODE_ENV == 'development'
            ? `http://127.0.0.1:${PORT}/js/metadata.json`
            : 'http://169.254.170.2/v2/metadata'
        const result = await axios.get(url)

        const container = result.data.Containers.find(e => e.Image.includes('tinyproxy') == false)

        res.render('index', {
            address: container.Networks[0].IPv4Addresses[0]
        })
    } catch (err) {
        return res.json({
            code: err.code, 
            message: err.message
        })
    }
})

/*
    curl http://localhost:3000/vote
*/
app.get('/vote', async (req, res) => {
    let up = await redis.get('up')
    let down = await redis.get('down')
    return res.send({ up: Number(up), down: Number(down) })
})

/*
    curl http://localhost:3000/vote \
        --header 'Content-Type: application/json' \
        --data '{"vote":"up"}'
*/
app.post('/vote', async (req, res) => {
    try {
        console.log('POST /vote: %j', req.body)
        console.log(req.body.vote)
        const result = await redis.incr(req.body.vote)
        console.log('result:', result)
        return res.send({ success: true, result: 'hello' })
    } catch (err) {
        console.log('ERROR: POST /vote: %s', err.message || err.response || err);
        res.status(500).send({ success: false, reason: 'internal error' });
    }
})

app.listen(PORT, () => {
    console.log(`listening on port ${PORT}`)
})
