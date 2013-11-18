(function(fontDescriptors, fontFaceDeclarations) {

	// Add a stylesheet with the latest @font-face declarations.
	// Since the font family or weight could change based on the size,
	// this is updated when the text size changes regardless of having no
	// explicit text size metadata.
	var styleSheetNode       = document.createElement('style');
	styleSheetNode.innerText = fontFaceDeclarations;
	document.getElementsByTagName('head')[0].appendChild(styleSheetNode);

	var styleSheets = document.styleSheets;
	for (var sheetIndex = 0; sheetIndex < styleSheets.length; sheetIndex++)
	{
		var styleSheet = styleSheets[sheetIndex];
		var cssRules   = styleSheet.cssRules;

		if (!cssRules)
		{
			continue;
		}

		for (var ruleIndex = 0; ruleIndex < cssRules.length; ruleIndex++)
		{
			var cssRule = cssRules[ruleIndex];

			if (!cssRule.style)
			{
				continue;
			}

			// Keep a reference to the original font style
			if (!cssRule.DTK_originalStyle)
			{
				cssRule.DTK_originalStyle = {
					fontWeight:  cssRule.style.fontWeight,
					fontStyle:   cssRule.style.fontStyle,
					fontStretch: cssRule.style.fontStretch
				};
			}

			var originalStyle = cssRule.DTK_originalStyle;
			var font          = cssRule.style.font;
			var fontFamily    = cssRule.style.fontFamily;

			if (!font && !fontFamily)
			{
				continue;
			}

			fontDescriptors.forEach(function(fontDescriptor)
			{
				if ((font && font.indexOf(fontDescriptor.textStyle) >= 0) ||
					(fontFamily && fontFamily.indexOf(fontDescriptor.textStyle) >= 0))
				{
					if (cssRule.cssText.indexOf('@font-face') < 0)
					{
						['fontWeight', 'fontStyle', 'fontStretch', 'fontSize'].forEach(function(rule)
						{
							if (!originalStyle[rule] && (rule in fontDescriptor))
							{
								cssRule.style[rule] = fontDescriptor[rule];
							}
						});
					}

					return false;
				}
			});
		}
	}
})();
