#!/bin/bash

if make test; then
  make publish_and_deploy
else
  make publish_failure
fi