Rank14LosSA-Classic
======
**Rank14LosSA-Classic** is a World of Warcraft: Classic AddOn used to auditorily notify you of important spells used around you. This addon is a complete rewrite of *Nogall's (Feenix-Warsong)* **_Rank14LosSA_**, which itself was a backport of **_GladiatorlosSA_**.
<p align="center">
  <img src="https://github.com/KevinTyrrell/Rank14LosSA-Classic/blob/master/res/Images/Thumbnail.png?raw=true" alt="Rank14LosSA Thumbnail"/>
</p>

- [SCREENSHOT](#screenshot)
- [DOWNLOAD](#download)
- [USAGE](#usage)
- [VERSION](#version)
- [LICENSE](#license)
- [CONTACT](#contact)

# SCREENSHOT

![Rank14LosSA Screenshot](res/Images/v2.0.0.png?raw=true "Rank14LosSA Screenshot")

*Screenshots may not always demonstrate the experience of the most recent release of Rank14LosSA.*

# DOWNLOAD

#### Automatic: [Curseforge / Twitch App](https://www.curseforge.com/wow/addons/rank14lossa-classic)

* (Recommended) Updates may/will install automatically.
* Download the [Twitch App](https://www.twitch.tv/downloads) and search `Rank14LosSA-Classic`

#### Manual| [GitHub Latest Release](https://github.com/KevinTyrrell/Rank14LosSA-Classic/releases/latest)

* Download `Rank14LosSA-Classic.zip` and unzip it.
* Ensure the folder is named `Rank14LosSA-Classic` and directly inside resides a `src/`, `/res/`, and `.toc` file(s).
* Place `Rank14LosSA-Classic/` into your `<CLASSICWOWHOME>/World of Warcraft\_classic_/Interface/Addons/` folder.
* Check this repository in the future for updated versions.

# USAGE

The addon will automatically notify you of incoming spell alerts. Ensure your in-game sound is turned on, as the addon uses the SFX sound channel to play sounds (*Note: This will be an option in the future*).

##### CLI (*Command Line Interface*) /Slash Commands

```
/rsa /rank14 /r14 /r14lossa /rank14lossa /lossa /sa /soundalerter /gsa /gladiatorlossa
```

| Command | Parameter | Result |
| :-----: | --------- | ------ |
|         |           | *List of commands are printed.*
| alerts  |           | *Alphabetical list of all alerts and their statuses are printed.*
| toggle  | Alert Name| *Alert is toggled on/off*.

##### Example

```
/rsa toggle Battle Stance
```

> Battle Stance is now: DISABLED

When enemy players cast Battle Stance, there will be no auditory warning. This will be saved during the next UI reload (`/reload`), logout, or game exit.

```
/soundalerter toggle Battle Stance
```

> Battle Stance is now: ENABLED

# LICENSE
* see [LICENSE](LICENSE.md) file

# VERSION 
* Version 2.0.0

# CONTACT
#### Kevin Tyrrell
* e-mail: KevinTearUl@gmail.com
