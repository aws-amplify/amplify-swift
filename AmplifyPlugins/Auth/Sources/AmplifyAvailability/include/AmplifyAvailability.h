#include <Availability.h>

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
static inline int getIOSVersionMinRequired(void) {
    return __IPHONE_OS_VERSION_MIN_REQUIRED;
}
#endif

#if TARGET_OS_OSX
static inline int getMACOSXVersionMinRequired(void) {
    return __MAC_OS_X_VERSION_MIN_REQUIRED;
}
#endif
