package funkin.backend;

import haxe.ds.StringMap;
import sys.io.File;

class LanguageHandler {
    private static final translations:StringMap<StringMap<String>> = new StringMap();
    private static var currentLanguage:String = "English"; //this var is defaulted to english to avoid weird errors
    private static var availableLanguages:Array<String>;

    public static function loadTranslations():Void {
		availableLanguages = [];
		
		// why not just grab from assets? so addons can add custom translations silly!!!
		var translationFiles: Array<String> = ["assets/data/Translations.csv"];
		#if ADDONS_ALLOWED
		for(addon in Addons.list){
			if(addon.disabled)continue;
			var path = 'addons/${addon.id}/data/Translations.csv';
			if(!FileSystem.exists(path))continue;
			translationFiles.push(path);
		}
		#end
		
		for(path in translationFiles){
			final csvData = File.getContent(path);
			final lines = csvData.split("\n");
			if (lines.length == 0) continue;

			// Parse the header (languages)
			final headers = lines[0].split(",");
			for(lang in headers.slice(1)){
				if(!availableLanguages.contains(lang)){
					trace(lang);
					availableLanguages.push(lang);
				}
			}

			for (i in 1...lines.length) {
				final row = lines[i].split(",");
				if (row.length < 2) continue;

				final key = row[0];
				final rowTranslations = new StringMap<String>();
				for (j in 1...headers.length) {
					if (j < row.length) {
						var rowTxt = "";
						var lastEsc = 0;
						var escIdx = row[j].indexOf("\\");
						while (escIdx >= 0 && escIdx < row[j].length - 1) { // ignore the \ if its the last char.
							rowTxt += row[j].substring(lastEsc, escIdx);
							rowTxt += switch (row[j].fastCodeAt(escIdx + 1)) {
								case "n".code: "\n";
								case "r".code: "\r";
								case "t".code: "\t";
								default: row[j].charAt(escIdx + 1); // fuck it just add the char (also allows \', \", \\)
							}

							lastEsc = escIdx + 2;
							escIdx = row[j].indexOf("\\", lastEsc);
						}
						rowTxt += row[j].substring(lastEsc, row[j].length);

						rowTranslations.set(headers[j], rowTxt);
					}
				}
				if(translations.exists(key)){
					for(k => v in rowTranslations)
						translations.get(key).set(k, v);
				}else
					translations.set(key, rowTranslations);
			}
		}
    }

    /**
     * Set the current language.
     * @param language pretty self explanatory
     */
    public static function setLanguage(language:String):Void {
        currentLanguage = language;
    }

    /**
    * Get a list of all languages available in the translations.
    * @return Array<String>
    */
    public static function getLanguages():Array<String> {
        return availableLanguages;
    }

    /**
     * Get a translated string for the current language.
     * @param key The key of the string to translate.
     * @return The translated string, or the key if no translation is found.
     */
    public static inline function _t(key:String):String {
        final row = translations.get(key);
        final translation = row != null ? row.get(currentLanguage) : null;
        return translation != null ? translation : key;
    }
    //i made this function inline since we use it a lot, so it will always stay loaded

    /**
     * Get a translated string for the current language, with optional arguments.
     * Usage: _t("score_txt", "100", "3") // in the csv you need to do this "Score: {0} | Fails: {1}"
     * @param key The key of the string to translate.
     * @param args Arguments to replace in the string.
     * @return The translated string, or the key if no translation is found.
     */
    public static inline function _formatT(key:String, args:Array<String>):String {
        final row = translations.get(key);
        var translation = row != null ? row.get(currentLanguage) : null;
        if (translation == null) translation = key;
        for (i in 0...args.length) {
            translation = translation.replace('{' + i + '}', args[i]);
        }
        translation = ~/\\{\\d+\\}/g.replace(translation, "");
        return translation;
    }
}

/* // prob i'll fix this idea, idk...
    final trans:String = (translations.get(key)).get(currentLanguage);
    if (trans != null) return trans;
*/