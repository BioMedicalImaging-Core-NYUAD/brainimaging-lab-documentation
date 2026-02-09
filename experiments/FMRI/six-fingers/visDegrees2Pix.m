function visDegrees2Pix()
    global screen;
    global parameters;

    parameters.textSize = round(parameters.textSizeDeg * screen.pixels_per_deg_width);

end