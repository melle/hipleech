# HipLeech

Downloads grade information from a given cevex Home.InfoPoint website. The output can be formatted as
Ascii, JSON or Markdown. If a JSON-file with the previous grade information is provided, only the diff
between the old and the current state is returned. By providing a Telegram API token and a chat ID,
it is possible to send the grades to a Telegram bot.

```
Usage:

    $ .build/x86_64-apple-macosx/debug/HipLeech <username> <password> <url>

Arguments:

    username - Username (provided by the school)
    password - Password (provided by the school)
    url - Address of the Home.Infopoint installation, i.e. https://www.name-of-the-school.de/homeInfoPoint/

Options:
    --output [default: ascii] - Output format, either ascii, json or markdown
    --previousState [default: ] - previous state file in json-format
    --token [default: ] - Telegram API token
    --chatID [default: ] - Telegram chat ID (i.e. "-6573342")
    --help - complete usage info
````
