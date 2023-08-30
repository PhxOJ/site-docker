#!/bin/bash
if [ ! -e /site/install_done ]; then
    if [ ! -e /site/manage.py ]; then
        echo "firstrun: Extracting data"
        cp -r --preserve=all /osite/. /site
        chown -R dmoj:dmoj /site
    fi
    echo "firstrun: Migrating database"
    python3 manage.py migrate
    python3 manage.py loaddata navbar
    python3 manage.py loaddata language_small
    # The next line is optional
    #python manage.py loaddata demo
    echo "firstrun: Done"
    touch /site/install_done
fi
service nginx start
service redis-server start
service supervisor start
tail -F /tmp/site.stderr.log
