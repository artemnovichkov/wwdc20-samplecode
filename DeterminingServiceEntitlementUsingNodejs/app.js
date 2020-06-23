/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Initial entry point for routing requests for the app.
*/

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Initial entry point for routing requests for the app.
*/
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');

const indexRouter = require('./routes/index');

const app = express();

app.use(logger('dev'));
app.use(express.json({ limit: '50mb', extended: true }));
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);

module.exports = app;
