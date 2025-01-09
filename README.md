# Pico Sound Dj

[#psdj-0#]

Pico Sound Dj, or PSDJ for short, is an alternative to the base music editor of pico8. It supports the whole pico8 music specs, uses a grid oriented layout and a simple D-pad + O/X/start control scheme inspired by [LDSJ, a game boy music sequencer](https://www.littlesounddj.com/lsd/index.php). This means that you can create music on the go using any handheld which has native support for pico8, and then use this music in your pico8 games.

Features :
- supports the whole pico8 music specs (it even includes a custom instrument editor)
- edit the music/SFX data of any local pico8 cartridge
- handheld compatible but still powerful control scheme with support for multi editing
- most importantly, multiple color schemes


## Installation

While you can use the BBS version to try PSDJ out, it is highly recommended, if you want to save and edit your local projects, to download the `.p8.png` cart and put it in your pico8 cart folder. On desktop you can use the `FOLDER` command on the pico8 command line to open the directory and simply drag it there. To install on a handheld, you'll need to locate the pico8 cart folder. For example on the miyoo mini, assuming you have the [pico8 wrapper](https://github.com/XK9274/pico-8-wrapper-miyoo) installed, it should be in something like `/mnt/SDCARD/App/pico/.lexaloffle/pico-8/carts/`.

Then you should be able to open PSDJ from splore.


## The basics -- a short tutorial

Note: PSDJ has been thought to have `X` as the lowest button (Nintendo's B) and `O` the rightmost button (Nintendo's A) on your gamepad. You can swap those two buttons using the "BTN MODE" in the settings.

PSDJ has 3 different screens. When launching the program, you will land on the Settings screen. This is where you can load one of your local pico8 project and save your modifications. For now, let's edit an empty project by moving to the Patterns screen by holding `X` and pressing `Right`.

[img]/media/14850/psdj_intro_1.png[/img]

You can now scroll around using the dpad. Let's now press `O` to activate an SFX on the given pattern and channel. You can also hold `O` and press
- `Right/Left` to increase/decrease the SFX number by one
- `Up/Down` to increase/decrease the SFX number by 16

These are the most common patterns in PSDJ :
- almost all things you can interact with are either values you can edit, which is done by holding `O` and pressing a direction, or buttons, which are used by pressing `O`.
- clear/deactivate a value by holding `X` and pressing `O`.
- navigate screens by holding `X` and pressing a direction.

Let's now edit this SFX. With the cursor on our newly activated SFX, hold `X` and press `Right` to enter the SFX screen and edit this SFX.

[img]/media/14850/psdj_intro_2.png[/img]

In here, you can add notes by pressing `O` in the notes column and edit the notes using `O+direction`.

Now simply press `START` to play back your SFX!


## How to use -- the details

The following assumes you know how the SFX/music system of pico8 works. If not, you can [learn about it in the official manual](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#SFX_Editor).

- You can navigate between screens by holding `X` and pressing `Left/Right`.


### Settings screen

Note that in the other screens the behaviour of the `START` button is overridden, so this is the best place to access the pico8 menu.

IMPORTANT: don't forget to save your changes before exiting the program! If you exit via the pico8 menu, or simply turn off your console, you will not be prompted for unsaved changes!

[img]/media/14850/psdj_4.png[/img]

Navigate the menu using `Up/Down`.

- open : browse your local pico8 files and load a project
    - `O/Right` to enter a directory or select a p8 file
    - `X/Left` to go back a directory
- open last : open the last edited project
- save : save the current project. Only available if a project is loaded 
- save as : choose a name to save the current state of the project at. Note that the new project file will be saved in your pico8 root folder.
    - `O` to input a letter, `X` to erase one letter
- clear : return the current project to a blank state (will not save)
- themes : hold `O` and press `Left/Right` to change the color theme
- button mode : hold `O` and press `Left/Right` to swap which buttons are considered `X` and `O`
- exit : exit PSDJ


### Patterns screen

The pattern screen is composed of 64 lines corresponding to the 64 pico8 patterns, 4 columns for each of the channels, and a "start loop", "end loop" and "stop" column.

[img]/media/14850/psdj_5.png[/img]

- Navigate using the D-pad
- Press `O` to activate a SFX on a given channel
    - Note that the inserted SFX value will be the last modified SFX to easily chain edits
- You can edit the value of a SFX by holding `O` and pressing `Right/Left/Up/Down`
- Hold `X` and press `O` to deactivate a SFX
- You can activate/deactivate the "start loop" / "end loop" / "stop" markers by pressing `O` on their column 

- Multi edition
    - Double click on `X` to enter select mode
    - In select mode, move the cursor around to define your selection
    - You can multi edit all the active values in the selection by holding `O` and pressing `Right/Left/Up/Down`
    - You can copy the selection/get out of select mode by pressing `X`
    - You can cut the selection by double clicking on `O`
    - When you are out of selection mode, you can paste at the cursor by holding `O` and pressing `START`

- Playback
    - press `START` to play/pause your music from pattern 0
    - hold `X` and press `START` to play the patterns from the cursor position

Hold `X` and press `Right` with the cursor on an active SFX to enter the SFX screen to edit it.


### SFX screen

The SFX screen is composed of a note editor section and an SFX settings section. You can simply navigate right to enter the settings section.

[img]/media/14850/psdj p8_4.png[/img]

- You can navigate between SFX from this screen by holding `X` and pressing `Up/Down`. Note that this is the only way to edit an SFX that isn't used in a pattern.

- Playback
    - press `START` to play/pause the SFX
    - hold `X` and press `START` to play the SFX starting from the cursor position

#### Note editor

The note editor let's you edit each of the 32 notes of the current SFX. Each note has 
- a pitch (`O+Up/Down` to add/remove and octave, `O+Right/Left` to add/remove a semitone)
- an instrument (if you go over 7, the number will then be colored to signify that a custom instrument is now used)
- a volume
- and an effect

When modifying a value, a note preview should be heard.

- The note editor supports multi edition, as the pattern one does
    - Double click on `X` to enter select mode
    - In select mode, move the cursor around to define your selection
    - You can multi edit all the active values in the selection by holding `O` and pressing `Right/Left/Up/Down`
    - You can copy the selection/get out of select mode by pressing `X`
    - You can cut the selection by double clicking on `O`
    - When you are out of selection mode, you can paste at the cursor by holding `O` and pressing `START`

When activating a note, the value of the previously modified note will be used to make chaining easier.


#### SFX settings editor

When you cursor is on the rightmost column, you can edit the values of the settings and filters for this SFX using the usual `O+Right/Left/Up/Down`.

Note: a value of 0 for "EDTM" means that the SFX is in pitch mode, while a value of 1 means it is in tracker mode. This doesn't change anything at all to the sound, it just changes the way pico8 will display the sfx in the official sound editor.

- Double click on `X` in the settings column to copy the whole SFX, including its settings and filters. You can then go to another SFX and hold `O` and press `START` to paste it.


#### Waveform editor

SFX 0 through 7 can be used as [custom instruments](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#SFX_Instruments). To use one of those SFX as a waveform instrument, simply press the "EDIT AS WAVE" button to enter the waveform editor.

[img]/media/14850/psdj_6.png[/img]

The waveform editor is composed of three parts that can be navigated to using `Up/Down`

In the first part you can set the zoom, which is a purely visual setting, toggle the bass mode, or go back to the note editor.

In the second and main part, you can edit your waveform :
- Navigate using `Left/Right`.
- Hold `O` and press `Up/Down` to modify the waveform at a given time point.
- Hold `O` and press `Left/Right` to copy the value of the current time point to the left/right.
- Press `START` to preview your waveform.

The last part corresponds to the usual SFX filters.


## Other notes and useful tools

To retrieve the music you made using PSDJ in your pico8 games, you could either copy the whole SFX and music data from your edited projects using a text editor, or use a tool like [renoiser](https://www.lexaloffle.com/bbs/?tid=36922), as explained in this video : https://www.youtube.com/watch?v=STzunIMtVYA


## Plans for the future

- When I get the time, and if I can squeeze the tokens enough for it, I would like to make a SFX overview screen, in which you would be able to copy or move your SFXs around, maybe multi edit some settings too. This would also be another way to enter the editing of an SFX, which could be nice if your SFX is not used in a pattern.


## Feedback

If you have used PSDJ and found a bug or would like to submit a feature request, don't hesitate to do it here (or on the github page once I'll set it to public access)!

I also have only tested PSDJ on my miyoo mini plus (and my computer), so please tell how it works for you if you have a different setup!

Also, if you find PSDJ useful in your projects, while your not obligated to, I would quite like to know about it!
