package funkin.backend;

class DifficultyRating {
	//this will eventually override any ratings on the meta.json for the official songs
	//we kill two birds with one stone by avoiding cheating and not having to check each meta.json file all the time
	public static var list:Map<String, Map<String, Array<Float>>> = [
			//<difficulty>: [<player>, <opponent>],
		'tutorial' => [
			'Maniac' => [8, 13.5]
			//make this not count for the awards maybe
		],
		'first-town-of-this-journey' => [
			'Maniac' => [7, 11],
			'Hard' => [5, 8.5],
			'Normal' => [4.5, 6]
		],
		'liquated' => [
			'Maniac' => [7.5, 10.5],
			'Hard' => [5.5, 8],
			'Normal' => [4, 4.5]
		],
		'why-do-you-hate-me' => [
			'Maniac' => [8.5, 11.5],
			'Hard' => [6, 6.5],
			'Normal' => [4, 5.5]
		],
		'quaoar' => [
			'Maniac' => [9, 12.5],
			'Hard' => [6.5, 9.5],
			'Normal' => [5.5, 6]
		],
		'crystallized' => [
			'Maniac' => [10, 14],
			'Hard' => [7.5, 13],
			'Normal' => [4.5, 8.5]
		],
		'nacreous-snowmelt' => [
			'Maniac' => [11, 15.5],
			'Hard' => [8, 11.5],
			'Normal' => [5, 6]
		],
		'lioness-pride' => [
			'Camellia' => [12.5],
			'Maniac' => [8, 6.5],
			'Hard' => [6.5, 6],
			'Normal' => [5, 5]
		],
		'ghost' => [
			'Maniac' => [13, 16.5],
			'Hard' => [8.5, 11],
			'Normal' => [6, 8]
		],
		'ghoul' => [
			'Maniac' => [14.5, 17],
			'Hard' => [10, 13.5],
			'Normal' => [7.5, 9.5]
		],
		'ghost-vip' => [
			'Maniac' => [14, 17.5],
			'Hard' => [9, 15.5],
			'Normal' => [6.5, 9]
		],
		'dance-with-silence' => [
			'Maniac' => [10.5, 12.5],
			'Hard' => [8, 8.5],
			'Normal' => [6, 7.5]
		],
		'burning-aquamarine' => [
			'Maniac' => [12.5, 15],
			'Hard' => [10.5, 12],
			'Normal' => [9.5, 10.5]
		],
		'tremendous' => [
			'Maniac' => [15.5, 20],
			'Hard' => [10, 16.5],
			'Normal' => [9, 12.5]
		],
		'racemization' => [
			'Maniac' => [10.5, 16.5],
			'Hard' => [9.5, 11.5],
			'Normal' => [7.5, 10.5]
		],
		'kisaragi' => [
			'Maniac' => [14, 18],
			'Hard' => [10.5, 15],
			'Normal' => [8.5, 10]
		],
		'compute it' => [
			'Maniac' => [15.5, 15.5],
			'Hard' => [9.5, 10.5],
			'Normal' => [8, 9.5]
		],
		'exit-this-earth\'s-atomosphere' => [
			'Maniac' => [15, 19.5],
			'Hard' => [10, 16],
			'Normal' => [7, 11]
		]
	];
}
