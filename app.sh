#!/bin/bash
export $(cat .env | xargs) && cabal run
