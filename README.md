# anytype-docker

Docker setup around [anytype-cli](https://github.com/anyproto/anytype-cli)

The primary intended use would be to connect an anytype bot account to your space. Then you can use the api to act as the bot account on your space.



## Troubleshooting

### panic: runtime error: invalid memory address or nil pointer dereference

Try removing the docker volume storing the anytype data and starting fresh.
