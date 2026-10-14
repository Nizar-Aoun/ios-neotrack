# Repo-root context only (not EasyPanel).
# EasyPanel uses build/web via web/Dockerfile copied by Flutter build.
FROM nginx:1.27-alpine

COPY web/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html/
RUN rm -f /usr/share/nginx/html/nginx.conf \
         /usr/share/nginx/html/Dockerfile \
         /usr/share/nginx/html/.dockerignore

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
