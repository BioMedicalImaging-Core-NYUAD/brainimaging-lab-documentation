function s3_endScreen(VP, pa)
% S3_ENDSCREEN - Brief thank-you screen.

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('TextSize', VP.window, 42);
DrawFormattedText(VP.window, 'Thank you for your participation!', 'center', 'center', [255 255 255]);
Screen('Flip', VP.window);
WaitSecs(pa.endScreenDuration);

end
