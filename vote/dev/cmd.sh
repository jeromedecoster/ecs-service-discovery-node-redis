#!/bin/bash
npx livereload . --wait 200 --extraExts 'ejs' & \
NODE_ENV=development npx nodemon --ext js,json index.js