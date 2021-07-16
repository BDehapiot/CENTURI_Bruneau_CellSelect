	setBatchMode(true);

//	open("D:/CurrentTasks/CENTURIProject_INMED_NadineBruneau/S245_gad67-Reelin_PFC_Fig10_1920x1923.tif");
//	open("D:/CurrentTasks/CENTURIProject_INMED_NadineBruneau/S243CTLM_gad67-Reelin_PFC_Fig10_1914x1311.tif");
	raw = getTitle();

/// ----- Dialog box ----- ///

	Dialog.create("BD_CellTracker-Bruneau");
	Dialog.setInsets(10, 0, 0);
	Dialog.addMessage("Parameters");
	Dialog.setInsets(-10, 0, 0);
	Dialog.addMessage("------------------------------------------");
	ROISize = Dialog.addNumber("ROIs size (pixels)", 40.0000); // parameters
	RBradius = Dialog.addNumber("RBradius (pixels), 0 = desactivate", 0.0000); // parameters
	FontSize = Dialog.addNumber("Font size (pixels)", 16.0000); // parameters
	
	Dialog.show();
	
	ROISize = Dialog.getNumber();
	RBradius = Dialog.getNumber();
	FontSize = Dialog.getNumber();

/// ----- Get variables ----- ///

	getDimensions(width,height,channels,slices,frames);
	getPixelSize (unit, pixelWidth, pixelHeight);

/// ----- Split channels ----- ///

	run("Split Channels");
	C1raw = "C1-"+raw;
	C2raw = "C2-"+raw; close(C2raw);
	C3raw = "C3-"+raw;
	
/// ----- Image pre-processing ----- ///	

	if (RBradius>0){
	selectWindow(C1raw);
	run("32-bit");
	run("Subtract Background...", "rolling="+RBradius+" stack");
	selectWindow(C3raw);
	run("32-bit");
	run("Subtract Background...", "rolling="+RBradius+" stack");
	}	
	
/// ----- Max. project channel #1 ----- ///
	
	selectWindow(C1raw);
	run("Z Project...", "projection=[Max Intensity]");
	C1raw_max = getTitle();
    
/// ----- Manually select cell of interest ----- ///
    
    run("Set Measurements...", "center redirect=None decimal=3");

	setBatchMode("show");
    
    setTool("multipoint");
    waitForUser("Please select center points for all areas of interest. Click OK when done");

	setBatchMode("hide");
    
    run("Clear Results");
    run("Measure");
    nROI = nResults;
 
	px = newArray(nROI);
	py = newArray(nROI);
    for (i=0; i<nResults; i++) {
	   	px[i] = getResult("XM",i);
		py[i] = getResult("YM",i);
		//the coordinates index from the top left corner
	    makeRectangle(px[i]-ROISize/2, py[i]-ROISize/2, ROISize, ROISize); 
	    roiManager("Add");
	    run("Select None");
    }

    roiManager("Show All without labels");
    if (isOpen("Results")) {selectWindow("Results"); run("Close");}

/// ----- Process data ----- ///
	
	run("Set Measurements...", "mean redirect=None decimal=3");

	C1MaxInt = newArray(nROI);
	C1MaxSlice = newArray(nROI);
	C3MaxInt = newArray(nROI);
	for(i=0; i<nROI; i++){

		// Find C1MaxSlice and get C1MaxInt
		selectWindow(C1raw);
		roiManager("Select", i);
		run("Duplicate...", "duplicate");
		C1raw_crop = getTitle();
		C1MeanInt = newArray(slices);
		for(j=0; j<slices; j++){
			setSlice(j+1); run("Select All"); run("Measure");
			C1MeanInt[j] = getResult("Mean",j);			
		}
		tempMax = Array.findMaxima(C1MeanInt,0);
		C1MaxSlice[i] = tempMax[0];
		C1MaxInt[i] = C1MeanInt[C1MaxSlice[i]];
		close(C1raw_crop);
		run("Select None"); run("Clear Results");

		// Get C3MaxInt (at C1MaxSlice)
		selectWindow(C3raw);
		roiManager("Select", i);
		run("Duplicate...", "duplicate");
		C3raw_crop = getTitle();
		setSlice(C1MaxSlice[i]+1); run("Select All"); run("Measure");
		C3MaxInt[i] = getResult("Mean",0);
		close(C3raw_crop);
		run("Select None"); run("Clear Results");
	}
	
//	Array.show(C1MaxInt);
//	Array.show(C1MaxSlice);
//	Array.show(C3MaxInt);

	selectWindow("Results"); run("Close");


/// ----- Fill Results table ----- ///

	for (i=0; i<nROI; i++) {
		setResult("C1MaxSlice",i,C1MaxSlice[i]);
		setResult("C1MaxInt",i,C1MaxInt[i]);
		setResult("C3MaxInt",i,C3MaxInt[i]);
	}

/// ----- Make a display ----- ///	

	setForegroundColor(255, 255, 255);
	newImage("ROIsMask", "8-bit color-mode", width, height, 1, slices, frames);
	ROIsMask = getTitle();
		
	for (i=0; i<nROI; i++) {
		roiManager("Select", i);
		setSlice(C1MaxSlice[i]+1);
		run("Draw", "slice");
		setTool("text");
		setFont("SansSerif", FontSize, " antialiased");
		setColor("white");
		drawString("ROI #"+i+1, px[i]-ROISize/2, py[i]-(ROISize/2)-FontSize/2);
		drawString(C1MaxInt[i], px[i]-ROISize/2, py[i]+(ROISize/2)+FontSize*1.75);
		drawString(C3MaxInt[i], px[i]-ROISize/2, py[i]+(ROISize/2)+FontSize*3);
	}

/// ----- Show results ----- ///	

	if (RBradius>0){
		selectWindow(C1raw);
		run("8-bit");
		selectWindow(C3raw);
		run("8-bit");
	}

	run("Merge Channels...", "c2="+C3raw+" c4="+ROIsMask+" c6="+C1raw+" create");
	run("Arrange Channels...", "new=312");

	close(C1raw_max);
	setTool("rectangle");
	setBatchMode("exit and display");

/// --- Close all --- ///

	waitForUser( "Pause","Click Ok when finished");
	macro "Close All Windows" { 
	while (nImages>0) { 
	selectImage(nImages); 
	close();
	}
	if (isOpen("Log")) {selectWindow("Log"); run("Close");} 
	if (isOpen("Summary")) {selectWindow("Summary"); run("Close");} 
	if (isOpen("Results")) {selectWindow("Results"); run("Close");}
	if (isOpen("ROI Manager")) {selectWindow("ROI Manager"); run("Close");}
	} 
