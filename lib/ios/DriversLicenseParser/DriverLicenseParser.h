/*
 
 Readme!!! in the target for that dll use "-all_load -licucore" Other Linker Flags in Build settings
 
 get DeviceId:: [DriverLicense dlpUniqueId];
 set serial (2 variants):: 
 1)file dlpSerial.txt
 2)[[NSUserDefaults standardUserDefaults] setValue:serial forKey:@"DriverLicenseParserCurrentSerial"];
 
 parse::
 - (BOOL)parseDLString:(NSString *)inputString hideSerialAlert:(BOOL)hideSerialAlert;
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIView.h>

@interface NSString (DriverLicenseReader)
- (NSDictionary *)parseDLStringForDict;
@end





//public
@interface DriverLicense : NSObject


- (BOOL)parseDLString:(NSString *)inputString hideSerialAlert:(BOOL)hideSerialAlert;
+(NSString*)dlpUniqueId;
//addon init
- (id)initWithInput:(NSString*)tracksString parseSucced:(BOOL**)success  hideSerialAlert:(BOOL)hideSerialAlert;



//new properties
@property (nonatomic,retain) NSString* countryCode;
@property (readonly,nonatomic,retain) NSString* documentType;

//technical info
@property (retain, nonatomic) NSDictionary *raw_parsed_fields;
@property (retain, nonatomic) NSString *specification;
@property (retain, nonatomic) NSString *parserName;
@property (readonly, nonatomic, retain) NSDictionary *fields;//parsedfields filtered (available fields)

//Document Info
@property (readonly, retain, nonatomic) NSString* licenseNumber;
@property (readonly, retain, nonatomic) NSString* expirationDate;//date
@property ( retain, nonatomic) NSString *IIN;//aliases
@property (readonly, retain, nonatomic) NSString */*IIN,*/issuerIdNum;//aliases

@property (readonly, retain, nonatomic) NSString* issuedBy;
@property (readonly, retain, nonatomic) NSString* endorsementsCode;
@property (readonly, retain, nonatomic) NSString* classificationCode;
@property (readonly, retain, nonatomic) NSString *restrictionsCode,*restrictionCode;//aliases
@property (readonly, retain, nonatomic) NSString* issueDate;//date

//Customer Info
@property (readonly, retain, nonatomic) NSString* fullName;
@property (readonly, retain, nonatomic) NSString* lastName;
@property (readonly, retain, nonatomic) NSString* firstName;
@property (readonly, retain, nonatomic) NSString* middleName;
@property (readonly, retain, nonatomic) NSString* birthdate;//date
@property (readonly, retain, nonatomic) NSString* nameSuffix;
@property (readonly, retain, nonatomic) NSString* namePrefix;

//Customer address
@property (readonly, retain, nonatomic) NSString* address1;
@property (readonly, retain, nonatomic) NSString* address2;
@property (readonly, retain, nonatomic) NSString* city;
@property (retain, nonatomic) NSString* jurisdictionCode;
@property (readonly, retain, nonatomic) NSString* postalCode;
@property ( retain, nonatomic) NSString* country;

//Customer physical description
@property (readonly, retain, nonatomic) NSString* gender;
@property (readonly, retain, nonatomic) NSString* eyeColor;
@property (readonly, retain, nonatomic) NSString* height;
@property (readonly, retain, nonatomic) NSString *weightLBS,*weightKG,*weight/*weight=weightLBS*/;
@property (readonly, retain, nonatomic) NSString* hairColor;
@property (readonly, retain, nonatomic) NSString* race;






- (NSArray *)availableFields;
- (NSString *)valueForField:(NSString *)field;
- (id)valueForDateField:(NSString *)field withFormat:(NSString *)dateFormat;





@end


/*
 NSDictionary *dict = [NSDictionary dictionaryWithObject:dlResult forKey:kDriverLicenceResultCameraKey];
 [[NSNotificationCenter defaultCenter] postNotificationName:kCameraGaveDLP object:self userInfo:dict];
 
 DriverLicense* dl = [container objectForKey:kDriverLicenceResultCameraKey];
 NSString* trackString = [container objectForKey:ReaderGaveData];
 */

