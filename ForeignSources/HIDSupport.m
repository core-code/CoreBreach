
#import "HIDSupport.h"

static void Handle_ValueAvailableCallback(void *inContext, IOReturn inResult, void *inSender);
static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);
static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);
static NSString *CopyDeviceElementNameString(IOHIDDeviceRef inIOHIDDeviceRef, IOHIDElementRef inIOHIDElementRef);

#ifdef DEBUGBLA
#define NSLogDebug(format, ...) \
NSLog(@"<%s:%d> %s, " format, \
strrchr("/" __FILE__, '/') + 1, __LINE__, __PRETTY_FUNCTION__, ## __VA_ARGS__)
#else // ifdef DEBUG
#define NSLogDebug(format, ...)
#endif // ifdef DEBUG

HIDSupport *sharedhid = nil;

@implementation HIDSupport

@synthesize hidDevices, started;

+ (HIDSupport *)sharedInstance
{
	if (sharedhid == nil)
		fatal("HIDSupport not allocated");
    //[[self alloc] init];
    
	return sharedhid;
}

+ (double)calibrateElementValue:(IOHIDValueRef)inIOHIDValueRef
{
	double result = 0.;
	if (inIOHIDValueRef)
    {
		result = IOHIDValueGetScaledValue(inIOHIDValueRef, kIOHIDValueScaleTypePhysical);
		
		IOHIDElementRef tIOHIDElementRef = IOHIDValueGetElement(inIOHIDValueRef);
		if (tIOHIDElementRef)
        {
#if 0
			double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
			if (granularity < 0.0) {
				printf("%s, BAD granularity!\n", __PRETTY_FUNCTION__);
				HIDSetupElementCalibration(tIOHIDElementRef);
				granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
				if (granularity < 0.0) {
					printf("%s, VERY BAD granularity!\n", __PRETTY_FUNCTION__);
				}
			}
			
#endif      // if 0
			if (result < IOHIDElement_GetCalibrationSaturationMin(tIOHIDElementRef)) {
				IOHIDElement_SetCalibrationSaturationMin(tIOHIDElementRef, result);
			}
			if (result > IOHIDElement_GetCalibrationSaturationMax(tIOHIDElementRef)) {
				IOHIDElement_SetCalibrationSaturationMax(tIOHIDElementRef, result);
			}
			
			result = IOHIDValueGetScaledValue(inIOHIDValueRef, kIOHIDValueScaleTypeCalibrated);
		}
	}
	
	return (result);
} /* Do_Element_Calibration */





// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) saveConfiguration: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	
	Boolean syncFlag = false;
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		CFStringRef keyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("HID Action #%d"), actionIndex);
		if (keyCFStringRef) {
			syncFlag |= HIDSaveElementPref(keyCFStringRef,
			                               kCFPreferencesCurrentApplication,
			                               actionRecs[actionIndex].fDeviceRef,
			                               actionRecs[actionIndex].fElementRef);
			CFRelease(keyCFStringRef);
		}
	}
	if (syncFlag) {
		CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
	}
} // saveConfiguration
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) restoreConfiguration: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
		CFStringRef keyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("HID Action #%d"), actionIndex);
		if (keyCFStringRef) {
			bzero(&actionRecs[actionIndex], sizeof(actionRecs[actionIndex]));
			if (HIDRestoreElementPref(keyCFStringRef, kCFPreferencesCurrentApplication, &actionRecs[actionIndex].fDeviceRef,
			                          &actionRecs[actionIndex].fElementRef))
			{
				// if the calibration parameters haven't been set yet…
				double_t granularity = IOHIDElement_GetCalibrationGranularity(actionRecs[actionIndex].fElementRef);
				if (granularity < 0.0) {
					// … do it now
					HIDSetupElementCalibration(actionRecs[actionIndex].fElementRef);
				}
                
                actionRecs[actionIndex].pMin = IOHIDElementGetPhysicalMin(actionRecs[actionIndex].fElementRef);
                actionRecs[actionIndex].pMax = IOHIDElementGetPhysicalMax(actionRecs[actionIndex].fElementRef);
                actionRecs[actionIndex].lMin = IOHIDElementGetLogicalMin(actionRecs[actionIndex].fElementRef);
                actionRecs[actionIndex].lMax = IOHIDElementGetLogicalMax(actionRecs[actionIndex].fElementRef);
                actionRecs[actionIndex].lRange = fabs(actionRecs[actionIndex].lMin) + fabs(actionRecs[actionIndex].lMax);
                actionRecs[actionIndex].pRange = fabs(actionRecs[actionIndex].pMin) + fabs(actionRecs[actionIndex].pMax);

                //	NSString *devEleName = Copy_DeviceElementNameString(actionRecs[actionIndex].fDeviceRef,				                                                    actionRecs[actionIndex].fElementRef);
                
			} // if HIDRestoreElementPref…
			CFRelease(keyCFStringRef);
		}   // if (keyCFStringRef)
	}   // for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++)
	
} // restoreConfiguration
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (IBAction) rebuild: (id) inSender {
	NSLogDebug(@"sender: <%@>", inSender);
	(void) HIDBuildMultiDeviceList(nil, nil, 0);
	[self restoreConfiguration:nil];
} // rebuild


- (NSString *)configItem:(int)item forDevice:(NSDictionary *)dev
{
    IOHIDDeviceRef tIOHIDDeviceRef = (IOHIDDeviceRef)[[dev objectForKey:@"deviceRef"] pointerValue];
    IOHIDElementRef tIOHIDElementRef = NULL;
    NSString *devEleName = nil;
    
    if (HIDConfigureSingleDeviceAction(tIOHIDDeviceRef, &tIOHIDElementRef, 10.0))
    {
        if (tIOHIDElementRef)
        {
            actionRecs[item].fDeviceRef = tIOHIDDeviceRef;
            actionRecs[item].fElementRef = tIOHIDElementRef;
            actionRecs[item].pMin = IOHIDElementGetPhysicalMin(tIOHIDElementRef);
            actionRecs[item].pMax = IOHIDElementGetPhysicalMax(tIOHIDElementRef);
            actionRecs[item].lMin = IOHIDElementGetLogicalMin(tIOHIDElementRef);
            actionRecs[item].lMax = IOHIDElementGetLogicalMax(tIOHIDElementRef);
            actionRecs[item].lRange = fabs(actionRecs[item].lMin) + fabs(actionRecs[item].lMax);
            actionRecs[item].pRange = fabs(actionRecs[item].pMin) + fabs(actionRecs[item].pMax);

            devEleName = CopyDeviceElementNameString(tIOHIDDeviceRef, tIOHIDElementRef);
            
            
            // if the calibration parameters haven't been set yet…
            double_t granularity = IOHIDElement_GetCalibrationGranularity(tIOHIDElementRef);
            if (granularity < 0)
            {
                HIDSetupElementCalibration(tIOHIDElementRef);
            }
            
            IOHIDValueRef tIOHIDValueRef;
            if (kIOReturnSuccess ==
                IOHIDDeviceGetValue(IOHIDElementGetDevice(tIOHIDElementRef), tIOHIDElementRef, &tIOHIDValueRef))
            {
//                    actionRecs[item].lValue = IOHIDValueGetIntegerValue(tIOHIDValueRef);
//                    actionRecs[item].pValue = IOHIDValueGetScaledValue(tIOHIDValueRef, kIOHIDValueScaleTypePhysical);
//                    actionRecs[item].cValue = [HIDSupport calibrateElementValue:tIOHIDValueRef];
                
                actionRecs[item].lValue = (int)(actionRecs[item].lMin + (actionRecs[item].lRange / 2.0));
                actionRecs[item].pValue = (int)(actionRecs[item].pMin + (actionRecs[item].pRange / 2.0));
                actionRecs[item].cValue = (int)(actionRecs[item].lMin + (actionRecs[item].lRange / 2.0));
            }
            
          //  NSLog(@" type usagep usage repc %i %i %i dev elem %x %x", IOHIDElementGetType(tIOHIDElementRef), IOHIDElementGetUsagePage(tIOHIDElementRef), IOHIDElementGetUsage(tIOHIDElementRef), tIOHIDDeviceRef, tIOHIDElementRef);
        }
    }
    
    return devEleName;
}

- (NSString *)nameOfItem:(int)item
{
    if (actionRecs[item].fDeviceRef && actionRecs[item].fElementRef)
        return CopyDeviceElementNameString(actionRecs[item].fDeviceRef , actionRecs[item].fElementRef);
    else
        return nil;
}

- (BOOL)item:(uint8_t)item identicalToItem:(uint8_t)otherItem
{
    return  actionRecs[item].fDeviceRef == actionRecs[otherItem].fDeviceRef &&
            actionRecs[item].fElementRef == actionRecs[otherItem].fElementRef;
}

- (void)clearItem:(uint8_t)item
{
    bzero(&actionRecs[item], sizeof(actionRecs[item]));
}

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (OSStatus) initHID
{
	OSStatus result = -1;
	
	// create the manager
	gIOHIDManagerRef = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
	if (gIOHIDManagerRef) {
		// open it
		IOReturn tIOReturn = IOHIDManagerOpen(gIOHIDManagerRef, kIOHIDOptionsTypeNone);
		if (kIOReturnSuccess == tIOReturn) {
			NSLogDebug(@"IOHIDManager (%p) creaded and opened!\n", (void *) gIOHIDManagerRef);
		} else {
			NSLog(@"Couldn’t open IOHIDManager.");
		}
	} else {
		NSLog(@"Couldn’t create a IOHIDManager.");
	}
	if (gIOHIDManagerRef) {
		// schedule with runloop
		IOHIDManagerScheduleWithRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		// register callbacks
		IOHIDManagerRegisterDeviceMatchingCallback(gIOHIDManagerRef, Handle_DeviceMatchingCallback, self);
		IOHIDManagerRegisterDeviceRemovalCallback(gIOHIDManagerRef, Handle_DeviceRemovalCallback, self);
	}
	
	require(HIDBuildMultiDeviceList(nil, nil, 0), Oops);
	
#if FALSE // set true to log devices
	{
		CFIndex idx, cnt = CFArrayGetCount(gDeviceCFArrayRef);
		for (idx = 0; idx < cnt; idx++) {
			IOHIDDeviceRef tIOHIDDeviceRef = (IOHIDDeviceRef) CFArrayGetValueAtIndex(gDeviceCFArrayRef, idx);
			if (!tIOHIDDeviceRef) {
				continue;
			}
			if (CFGetTypeID(tIOHIDDeviceRef) != IOHIDDeviceGetTypeID()) {
				continue;
			}
			
			HIDDumpDeviceInfo(tIOHIDDeviceRef);
		}
		
		fflush(stdout);
	}
#endif // if TRUE
	
	[self restoreConfiguration:nil];
	
Oops:;
	return (result);
}  

- (void)stopHID
{
    if (ioHIDQueueRefsCFArrayRef)
    {
        CFIndex idx, cnt = CFArrayGetCount(ioHIDQueueRefsCFArrayRef);
        for (idx = 0; idx < cnt; idx++) {
            IOHIDQueueRef tIOHIDQueueRef = (IOHIDQueueRef) CFArrayGetValueAtIndex(ioHIDQueueRefsCFArrayRef, idx);
            if (!tIOHIDQueueRef) {
                continue;
            }
            
            IOHIDQueueStop(tIOHIDQueueRef);
            IOHIDQueueRegisterValueAvailableCallback(tIOHIDQueueRef, NULL, NULL);
            IOHIDQueueUnscheduleFromRunLoop(tIOHIDQueueRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        }
        
        CFRelease(ioHIDQueueRefsCFArrayRef);
        ioHIDQueueRefsCFArrayRef = NULL;
    }
}

- (void)startHID
{
    started = YES;
    
    if (ioHIDQueueRefsCFArrayRef) {
        CFRelease(ioHIDQueueRefsCFArrayRef);
    }
    
    ioHIDQueueRefsCFArrayRef = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
        if (actionRecs[actionIndex].fDeviceRef) {
            IOHIDQueueRef tIOHIDQueueRef = NULL;
            
            // see if we already have a queue for this device
            int idx, cnt = CFArrayGetCount(ioHIDQueueRefsCFArrayRef);
            for (idx = 0; idx < cnt; idx++) {
                IOHIDQueueRef tempIOHIDQueueRef = (IOHIDQueueRef) CFArrayGetValueAtIndex(ioHIDQueueRefsCFArrayRef, idx);
                if (!tempIOHIDQueueRef) {
                    continue;
                }
                if (actionRecs[actionIndex].fDeviceRef == IOHIDQueueGetDevice(tempIOHIDQueueRef)) {
                    tIOHIDQueueRef = tempIOHIDQueueRef; // Found one!
                    IOHIDQueueStop(tIOHIDQueueRef);     // (we'll restart it below)
                    break;
                }
            }
            if (!tIOHIDQueueRef) {      // nope, create one
                tIOHIDQueueRef = IOHIDQueueCreate(kCFAllocatorDefault, actionRecs[actionIndex].fDeviceRef, 256, 0);
                if (tIOHIDQueueRef) {   // and add it to our array of queues
                    CFArrayAppendValue(ioHIDQueueRefsCFArrayRef, tIOHIDQueueRef);
                }
            }
            if (tIOHIDQueueRef) {
                IOHIDQueueAddElement(tIOHIDQueueRef, actionRecs[actionIndex].fElementRef);
                IOHIDQueueRegisterValueAvailableCallback(tIOHIDQueueRef, Handle_ValueAvailableCallback, self);
                IOHIDQueueScheduleWithRunLoop(tIOHIDQueueRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
                IOHIDQueueStart(tIOHIDQueueRef);    // (re?)start it
            }
        }
    }
}

// initHID
// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

- (OSStatus) termHID {
	if (gIOHIDManagerRef) {
		if (ioHIDQueueRefsCFArrayRef) {
			CFRelease(ioHIDQueueRefsCFArrayRef);
			ioHIDQueueRefsCFArrayRef = NULL;
		}
		
        
		IOHIDManagerRegisterDeviceMatchingCallback(gIOHIDManagerRef, NULL, NULL);
		IOHIDManagerRegisterDeviceRemovalCallback(gIOHIDManagerRef, NULL, NULL);
		IOHIDManagerUnscheduleFromRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
	if (gElementCFArrayRef) {
		CFRelease(gElementCFArrayRef);
		gElementCFArrayRef = NULL;
	}
	if (gDeviceCFArrayRef) {
		CFRelease(gDeviceCFArrayRef);
		gDeviceCFArrayRef = NULL;
	}
	if (gIOHIDManagerRef) {
		IOHIDManagerClose(gIOHIDManagerRef, 0);
		gIOHIDManagerRef = NULL;
	}
	
	return (noErr);
}   // termHID

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------

- (void) deviceMatchingResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef {
#pragma unused (inResult, inSender, inIOHIDDeviceRef)
	NSLogDebug(@"result: %i, sender: %p, device %p", inResult, inSender, inIOHIDDeviceRef);
#ifdef DEBUGBLA
	HIDDumpDeviceInfo(inIOHIDDeviceRef);
#endif // DEBUG
	
	HIDRebuildDevices();
	[self restoreConfiguration:nil];
} // deviceMatchingResult

// --------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------
- (void) deviceRemovalResult: (IOReturn) inResult sender: (void *) inSender device: (IOHIDDeviceRef) inIOHIDDeviceRef {
#pragma unused (inResult, inSender, inIOHIDDeviceRef)
	NSLogDebug(@"result: %i, sender: %p, device %p", inResult, inSender, inIOHIDDeviceRef);
#ifdef DEBUGBLA
	HIDDumpDeviceInfo(inIOHIDDeviceRef);
#endif // DEBUG
	
	HIDRebuildDevices();
	[self restoreConfiguration:nil];
} // deviceRemovalResult


- (void) valueAvailableResult: (IOReturn) inResult sender: (void *) inSender {
#pragma unused (inResult, inSender)
	NSLogDebug(@"result: %i, sender: %p", inResult, inSender);
	
	while (TRUE) {
		IOHIDValueRef tIOHIDValueRef = IOHIDQueueCopyNextValue((IOHIDQueueRef) inSender);
		if (!tIOHIDValueRef) {
			break;                        // no more data
		}
		for (int actionIndex = 0; actionIndex < kNumActions; actionIndex++) {
			if (!actionRecs[actionIndex].fDeviceRef || !actionRecs[actionIndex].fElementRef) {
				continue;
			}
			if (actionRecs[actionIndex].fElementRef != IOHIDValueGetElement(tIOHIDValueRef)) {
				continue;
			}
			

            actionRecs[actionIndex].lValue = IOHIDValueGetIntegerValue(tIOHIDValueRef);
            actionRecs[actionIndex].pValue = IOHIDValueGetScaledValue(tIOHIDValueRef, kIOHIDValueScaleTypePhysical);
            actionRecs[actionIndex].cValue = [HIDSupport calibrateElementValue:tIOHIDValueRef];
            
			
			NSLogDebug(@"element # %d = { value: %6.2f %6.2f %6.2f }.\n", actionIndex, actionRecs[actionIndex].cValue, actionRecs[actionIndex].pValue, actionRecs[actionIndex].lValue);
		}
		
		// fflush( stdout );
	}
}   // valueAvailableResult:sender


- (double)valueOfItem:(int)item
{
//    return (actionRecs[item].cValue - actionRecs[item].lMin) / actionRecs[item].lRange;
//    return (actionRecs[item].pValue - actionRecs[item].pMin) / actionRecs[item].pRange;
    return (actionRecs[item].lValue - actionRecs[item].lMin) / actionRecs[item].lRange;
}

- (void)printItem:(int)actionIndex
{
    NSLog(@"element # %d = { c %6.2f p %6.2f l %6.2f min %6.2f max %6.2f range %6.2f }.\n", actionIndex, actionRecs[actionIndex].cValue, actionRecs[actionIndex].pValue, actionRecs[actionIndex].lValue, actionRecs[actionIndex].lMin, actionRecs[actionIndex].lMax, actionRecs[actionIndex].lRange);
}

- (double)maxOfItem:(int)item
{
    return actionRecs[item].lMax;
}

- (BOOL)isButton:(int)item
{
    if (fabsf([self maxOfItem:item] - 1.0) < 0.001)
        return YES;
    else
        return NO;
}

- (void)dealloc
{
    //NSLog(@"hid dealloc");
    sharedhid = nil;
    [self termHID];
    [hidDevices release];
    [super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
        if (sharedhid)
            fatal("HID inited twice");
        sharedhid = self;
        [self initHID];
        
       NSMutableArray *tmpDevices = [[NSMutableArray alloc] init];
        char cstring[256];
        
        if (!HIDBuildDeviceList(0, 0))
        {
            [tmpDevices release];

            return nil;
        }
        
        IOHIDDeviceRef _device = HIDGetFirstDevice();
        
        
        while (_device != NULL)
        {
            uint32_t usagePage = IOHIDDevice_GetUsagePage(_device);
            uint32_t usage     = IOHIDDevice_GetUsage(_device);
            if (!usagePage || !usage) {
                usagePage = IOHIDDevice_GetPrimaryUsagePage(_device);
                usage     = IOHIDDevice_GetPrimaryUsage(_device);
            }
            if (!(usagePage == kHIDPage_GenericDesktop && ((usage == kHIDUsage_GD_Joystick) ||
                                                           (usage == kHIDUsage_GD_GamePad) || 
                                                           (usage == kHIDUsage_GD_Keypad) || 
                                                           (usage == kHIDUsage_GD_Wheel))))
            {
                _device = HIDGetNextDevice(_device);
                continue;
            }
            
            NSMutableDictionary *dev = [[NSMutableDictionary alloc] init];
            
            [dev setObject:[NSValue valueWithPointer:_device] forKey:@"deviceRef"];
            
            NSString *man = (NSString *)IOHIDDevice_GetManufacturer(_device);
            if (man)
                [dev setObject:man forKey:@"manufacturer"];
            
            NSString *prod = (NSString *)IOHIDDevice_GetProduct(_device);
            if (prod)
                [dev setObject:prod forKey:@"product"];
            
            long vendorID = IOHIDDevice_GetVendorID(_device);
            if (vendorID)
            {
                [dev setObject:[NSNumber numberWithLong:vendorID] forKey:@"vendorID"];
                
                if (HIDGetVendorNameFromVendorID(vendorID, cstring)) 
                    [dev setObject:[NSString stringWithUTF8String:cstring] forKey:@"vendor"];
            }
            long productID = IOHIDDevice_GetProductID(_device);
            if (productID)
            {
                [dev setObject:[NSNumber numberWithLong:productID] forKey:@"productID"];
                
                if (HIDGetProductNameFromVendorProductID(vendorID, productID, cstring)) 
                {
                    [dev setObject:[NSString stringWithUTF8String:cstring] forKey:@"product"];
                }
            }
            
            //        NSString *ser = (NSString *)IOHIDDevice_GetSerialNumber(_device);
            //        if (ser)
            //            [dev setObject:ser forKey:@"serial"];
            
            [dev setObject:$stringf(@"%@ %@", [dev objectForKey:@"manufacturer"] ? [dev objectForKey:@"manufacturer"] : [dev objectForKey:@"vendor"], [dev objectForKey:@"product"])  forKey:@"name"];
            
            
            [tmpDevices addObject:dev];
            [dev release];
            _device = HIDGetNextDevice(_device);
        }
        
        hidDevices = [[NSArray alloc] initWithArray:tmpDevices];
        [tmpDevices release];
  //      NSLog(@"%@", [hidDevices description]);
        

	}
    
	return self;
}
@end

#pragma mark *	IOHID Callbacks *
// ----------------------------------------------------

static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
	// NSLogDebug();
	// call the class method
	[(HIDSupport *) inContext deviceMatchingResult:inResult
                                            sender:inSender
                                            device:inIOHIDDeviceRef];
}   // Handle_DeviceMatchingCallback

static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef) {
	// NSLogDebug();
	// call the class method
	[(HIDSupport *) inContext deviceRemovalResult:inResult
                                           sender:inSender
                                           device:inIOHIDDeviceRef];
}   // Handle_DeviceRemovalCallback

static void Handle_ValueAvailableCallback(void *inContext, IOReturn inResult, void *inSender) {
	// NSLogDebug();
	// call the class method
	[(HIDSupport *) inContext valueAvailableResult:inResult sender:inSender];
}   // Handle_ValueAvailableCallback



// Copyright (C) 2010 Apple Inc. All Rights Reserved.


static NSString *CopyDeviceElementNameString(IOHIDDeviceRef inIOHIDDeviceRef, IOHIDElementRef inIOHIDElementRef)
{
	NSString *result = NULL;
	if (inIOHIDDeviceRef && inIOHIDElementRef) {
		char cstrElement[256] = "----";
		// if this is not a valid device
		if (CFGetTypeID(inIOHIDDeviceRef) != IOHIDDeviceGetTypeID()) {
			return (result);
		}
		// if this is not a valid element
		if (CFGetTypeID(inIOHIDElementRef) != IOHIDElementGetTypeID()) {
			return (result);
		}
        
		CFStringRef eleCFStringRef = IOHIDElementGetName(inIOHIDElementRef);
		if (eleCFStringRef) {
			(void) CFStringGetCString(eleCFStringRef, cstrElement, sizeof(cstrElement), kCFStringEncodingUTF8);
		} else {
			long vendorID = IOHIDDevice_GetVendorID(inIOHIDDeviceRef);
			long productID = IOHIDDevice_GetProductID(inIOHIDDeviceRef);
			if (!HIDGetElementNameFromVendorProductCookie(vendorID, productID,
			                                              IOHIDElementGetCookie(inIOHIDElementRef),
			                                              cstrElement))
			{
				long usagePage = IOHIDElementGetUsagePage(inIOHIDElementRef);
				long usage = IOHIDElementGetUsage(inIOHIDElementRef);
				if (!HIDGetElementNameFromVendorProductUsage(vendorID, productID, usagePage, usage, cstrElement)) {
					eleCFStringRef = HIDCopyUsageName(usagePage, usage);
					if (eleCFStringRef) {
						(void) CFStringGetCString(eleCFStringRef, cstrElement, sizeof(cstrElement), kCFStringEncodingUTF8);
						CFRelease(eleCFStringRef);
					} else {
						sprintf(cstrElement, "ele: %08lX:%08lX", usagePage, usage);
					}
				}   // if ( !HIDGetElementNameFromVendorProductUsage(...) )
				
			}       // if ( !HIDGetElementNameFromVendorProductCookie(...) )
			
		}           // if ( eleCFStringRef )
		
		result = [NSString stringWithFormat:@"%s", cstrElement];
	}
	
	return (result);
}   // Copy_DeviceElementNameString