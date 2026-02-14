---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
description: ""
image: ""
thumbnail: ""
camera: ""
focal_length: ""
aperture: ""
iso: ""
location: ""
year: {{ dateFormat "2006" .Date }}
month: {{ dateFormat "1" .Date }}
draft: false
---
