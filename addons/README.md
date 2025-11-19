# Addons System
for the people in the know this is just psych engine lmfao  
except you can't replace images

for the people NOT in the know  
basically each folder is a mini-`assets` folder  
if you copy the `assets` folder and throw it in a folder (like `addons/YourFolderHere`) it'd pretty much work the exact same  

the only exception is that addons "require" a `meta.json` looking something like this:  
```json
{
	name: "Unknown",
	description: "No description given.",
	licensed: false
}
```

## Adding a song
make a folder in `songs/`  
this should contain the chart(s), metadata, and song assets
```json
{
	songName: "Unknown",
	subtitle: "this shows up in freeplay",
	instComposer: "Camellia",
	vocalComposer: "LiterallyNoOne",
	genre: "Electronic",
	album: "", // the album this song is from, not the art
	jacket: "", // the artist who made the jacket art, not the path to it
	hasVocals: true,
	hasModchart: true, // will affect score saving if this is true

	player: "bf",
	spectator: "gf",
	enemy: "camellia",
	stage: "studio",

	charter: {
		Maniac: "Foxeru",
		Hard: "Foxeru",
		Normal: "Foxeru",
	},
	// [opponent, player side (default)]
	rating: {
		Camellia: [15, 15],
		Maniac: [10.5, 8.5], 
		Hard: [8, 6],
		Normal: [5, 4]
	},

	// bpm/time signature changes
	// is millisecond based and IS affected by map/song offset
	timingPoints: [
		{
			time: 0,
			bpm: 120,
			beatsPerMeasure: 4
		}
	]
}
```

then, add a week json in `weeks/` (there should already be one in `template.zip`)

## Adding a stage
assuming you already added a song, you need to edit your song's `meta.json`

after that, make sure you have a json for the stage in `stages/`
```json
{
	zoom: 0.64,

	spectatorPos: [775, -350],
	playerPos: [1200, -220],
	opponentPos: [310, -220],

	cameraPos: [950, 140]
}
```

optionally you can have a script for the stage (same name as the json)  
