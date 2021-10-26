#!/bin/bash
. config.docker

docker system info | grep -qE 'Username'
if [ $? -eq 1 ]; then
	echo "Connexion docker required"
	docker login --username wyzengroup 2>/dev/null

	if [ $? -eq 1 ]; then
		echo "Erreur de connexion"
		exit 1
	fi
fi

docker push ${VENDOR}/${IMAGE}:${TAG}

#docker tag ${VENDOR}/${IMAGE}:${TAG} ${VENDOR}/${IMAGE}:latest && docker push ${VENDOR}/${IMAGE}:latest
