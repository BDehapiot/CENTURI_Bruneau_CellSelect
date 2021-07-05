/// ----- Get variables ----- ///

	getDimensions(width,height,channels,slices,frames);
	getPixelSize (unit, pixelWidth, pixelHeight);

/// ----- Max. project channel #1 ----- ///

	raw = getTitle();
	run("Duplicate...", "duplicate channels=1");
	C1raw = getTitle();
	run("Z Project...", "projection=[Max Intensity]");
	C1raw_max = getTitle();
    
/// ----- Manually select cell of interest ----- ///
    
    run("Set Measurements...", "center redirect=None decimal=3");
    
    setTool("multipoint");
    waitForUser("Please select center points for all areas of interest. Click OK when done")
    run("Clear Results");
    run("Measure");
    for (i=0; i<nResults; i++) {
   	px = getResult("XM",i);
	py = getResult("YM",i);
    makeRectangle(px-20, py-20, 40, 40); //the coordinates index from the top left corner
    roiManager("Add");
    run("Select None");
    }

	nROI = nResults;
    roiManager("Show All without labels");
    if (isOpen("Results")) {selectWindow("Results"); run("Close");}

/// ----- ??? ----- ///
	
	run("Set Measurements...", "mean redirect=None decimal=3");

	for(i=0; i<nROI; i++){
		selectWindow(C1raw);
		roiManager("Select", i);
		run("Duplicate...", "duplicate");
		C1raw_crop = getTitle(); 
		run("Select All"); 
		MeanInt = getProfile();
		Array.show(MeanInt)
//		Array.getStatistics(MeanInt,min,max);	
//		MaxSlice = indexOfArray(MeanInt,max);
		
		stop
	}

	for(i=0; i<nROI; i++){
		selectWindow(C1raw);
		roiManager("Select", i);
		run("Duplicate...", "duplicate");
		C1raw_crop = getTitle();
		MeanInt = newArray(slices);
		for(j=0; j<slices; j++){
			setSlice(j+1); run("Select All"); run("Measure");
			MeanInt[j] = getResult("Mean",0);			
		}
		test = Array.findMaxima(MeanInt,0);
		stop
		//close("C1raw_crop");
		//run("Select None");
	}