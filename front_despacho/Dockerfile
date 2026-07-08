# Etapa 1: Construcción/Compilación (Usando Node ligero)
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build --if-present

# Etapa 2: Imagen final minimalista con Nginx para servir el contenido
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
# Si el proyecto no genera carpeta dist, copiamos la raíz directamente
COPY --from=build /app /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
