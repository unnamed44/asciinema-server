#!/bin/bash

bundle exec rake db:create db:migrate
bundle exec rake
