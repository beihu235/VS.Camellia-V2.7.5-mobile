function create() {
	if (Settings.data.gameplayModifiers['playingSide'] == 'Opponent') {
		closeFile();
		return;
	}

	game.playfield.leftSide.skin = 'holofunk';
}