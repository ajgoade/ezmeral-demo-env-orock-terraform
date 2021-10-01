#!/bin/bash

for var in `cat ./generated/env-variables`
do
export $var
done