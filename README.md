# What is Bitrix?

`Bitrix CMS` is professional management system for websites and online stores.

`Bitrix24` is a free (for small businesses) social enterprise platform. It is a united work space which handles the many aspects of daily operations and tasks.

# How to use this image

```console
$ docker run --name some-bitrix --network some-bitrix -d lookinio/bitrix
```
To use an external SMTP server, you have to provide the connection details. To configure Bitrix to use SMTP add:

- `-e SMTP_AUTH=...`
- `-e SMTP_FROM=...`
- `-e SMTP_HOST=...`
- `-e SMTP_PASSWORD=...` 
- `-e SMTP_PORT=...`
- `-e SMTP_TLS=...`
- `-e SMTP_TLS_CERTCHECK=...`
- `-e SMTP_TLS_STARTTLS=...`

Check the [msmtp man page](https://manpages.debian.org/testing/msmtp/msmtp.1.en.html#CONFIGURATION_FILES) for details.
