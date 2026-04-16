#!/bin/sh

cd /usr/lib/enigma2/python/Plugins/Extensions && rm -rf WhatToWatch && wget --no-check-certificate https://github.com/Ahmed-Mohammed-Abbas/WhatToWatch/archive/refs/heads/main.zip -O WhatToWatch.zip && unzip WhatToWatch.zip && mv WhatToWatch-main WhatToWatch && rm WhatToWatch.zip && killall -9 enigma2