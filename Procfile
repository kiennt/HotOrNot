web1: bundle exec thin -R config.ru start -p $PORT -e ${RACK_ENV:-development} -P./tmp/thin-1.pid -d -l./tmp/log
web2: bundle exec thin -R config.ru start -p $PORT -e ${RACK_ENV:-development} -P./tmp/thin-2.pid -d -l./tmp/log
web3: bundle exec thin -R config.ru start -p $PORT -e ${RACK_ENV:-development} -P./tmp/thin-3.pid -d -l./tmp/log
web4: bundle exec thin -R config.ru start -p $PORT -e ${RACK_ENV:-development} -P./tmp/thin-4.pid -d -l./tmp/log
