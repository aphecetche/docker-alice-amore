#include "TString.h"
#include "TObjArray.h"
#include "TTimeStamp.h"
#include "TRegexp.h"
#include "TGrid.h"
#include "TGridResult.h"
#include "AliCDBManager.h"
#include "AliCDBStorage.h"
#include "AliCDBEntry.h"
#include "AliLog.h"
#include "TSystem.h"
#include <iostream>
#include <sstream>
#include <string>

// compile with something like : 
//
// g++ -o amore_copy_cdb `root-config --cflags` -I$ALICE_ROOT/include amore_copy_cdb.cxx `root-config --libs` -L$ALICE_ROOT/lib -lCDB 
//

/******************************************************************************
 *
 * Program to create a local CDB for online usage
 * 1) For objects with run-range run-inf, the last available object is taken
 *    from the RAW OCDB and copied locally if not already there
 * 2) For objects with run-range run-run, the last available object is taken,
 *   going backwards till one available is found, and saved locally with
 *   run-range (run as original)-(infinity).
 *   For tracking purposes, the original run-range is stored as an addition
 *   in the comment in the metadata.
 *
 *****************************************************************************/

int getPreviousRun(int current, int attempts)
{
 // 'current' is the current run number.
 // 'attempts' is how many attempts we made so far to find a run.
 // If 'attempt' is smaller than 8 we return (current - which) otherwise we go
 // back from current exponentially fast (run, run-2, run-4, run-8,...).
 // The idea behind this algorithm is to find the closest previous run while
 // not
 // testing all of them as it would be too long. Here we are sure that we won't
 // test more
 // than 28 runs before choosing the default one (8 immediate and then up to
 // 2^20=1000000).

 int linearRange = 8; // number of attempts in linear search

 if (attempts < linearRange) {
  return (current - (attempts + 1));
 } else {
  return (current - linearRange - pow(2, attempts - linearRange + 1)); // goes back from current
                                                                       // exponentially fast (run,
                                                                       // run-2, run-4, run-8,...)
 }
}

Bool_t FilenameToId(TString &filename, AliCDBId &id)
{
 // build AliCDBId from full path filename
 // (fDBFolder/path/Run#x_#y_v#z_s0.root)

 TString idPath = filename(0, filename.Last('/'));
 id.SetPath(idPath);
 if (!id.IsValid())
  return kFALSE;

 filename = filename(idPath.Length() + 1, filename.Length() - idPath.Length());

 Ssiz_t mSize;
 // valid filename: Run#firstRun_#lastRun_v#version_s0.root
 TRegexp keyPattern("^Run[0-9]+_[0-9]+_v[0-9]+_s0.root$");
 keyPattern.Index(filename, &mSize);
 if (!mSize) {
  Ssiz_t oldmSize;
  TRegexp oldKeyPattern("^Run[0-9]+_[0-9]+_v[0-9]+.root$");
  oldKeyPattern.Index(filename, &oldmSize);
  if (!oldmSize) {
   // AliDebug( 2, Form( "Bad filename <%s>.", filename.Data() ) );
   return kFALSE;
  } else {
   // AliDebug( 2, Form( "Old filename format <%s>.", filename.Data() ) );
   id.SetSubVersion(-1);
  }

 } else {
  id.SetSubVersion(-1);
 }

 filename.Resize(filename.Length() - sizeof(".root") + 1);

 TObjArray *strArray = dynamic_cast<TObjArray *>(filename.Tokenize("_"));

 TObjString* firstRunString = dynamic_cast<TObjString *>(strArray->At(0));
 id.SetFirstRun(atoi(firstRunString->GetString().Data() + 3));
 TObjString* lastRunString = dynamic_cast<TObjString *>(strArray->At(1));
 id.SetLastRun(atoi(lastRunString->GetString().Data()));

 TObjString* verString = dynamic_cast<TObjString *>(strArray->At(2));
 id.SetVersion(atoi(verString->GetString().Data() + 1));

 delete strArray;
 return kTRUE;
}

int GetLatestVersion(const char *path, Int_t run, TString dbFolder)
{
 TObjArray validFileIds;
 validFileIds.SetOwner(1);

 TString filter = Form("CDB:first_run<=%d and CDB:last_run>=%d", run, run);
 TString pattern(".root");
 TString folderCopy(Form("%s/%s/Run", dbFolder.Data(), path));
 TGridResult *res = gGrid->Query(folderCopy, pattern, filter, "-y -m");

 AliCDBId validFileId;
 if (res->GetEntries() == 1) {
  TString filename = res->GetKey(0, "lfn");
  if (filename == "") {
   Printf("The entry found has empty filename!");
   return -1;
  }

  filename = filename(dbFolder.Length(), filename.Length() - dbFolder.Length());
  if (FilenameToId(filename, validFileId)) {
   return validFileId.GetVersion();
  } else {
   Printf("Unable to get FileId from filename");
   return -1;
  }
 } else {
  Printf("No entries found!");
  return -1;
 }

 delete res;
}

void copyCDB(Int_t runnr=0, const char *toURI = "local:///local/cdb")
{
 AliCDBManager *man = AliCDBManager::Instance();
 // determine dynamically the current year
 TTimeStamp *ts = new TTimeStamp();
 Int_t year = ts->GetDate() / 10000;
 TString dbFolder(TString::Format("/alice/data/%d/OCDB", year));
 TString fullPath(TString::Format("alien://folder=%s", dbFolder.Data()));
 man->SetDefaultStorage(fullPath.Data());
 man->SetRun(runnr);
 // man->SetCacheFlag(kTRUE);
 man->SetDrain(toURI);
 TString baseFolder(toURI);
 if (baseFolder.BeginsWith("local://")) {
  baseFolder.Remove(0, 8);
 } else {
  Printf("In this macro the drain storage is supposed to be a local one. "
    "Exiting!");
  return;
 }

 // array with the calibration types for which objects are saved per-run
 // and no default object is provided (at least in raw OCDB 2012, in principle
 // it should be checked again every year)
 std::vector<TString> perRunCalPathsVec;
 perRunCalPathsVec.push_back("EMCAL/Calib/LED");
 perRunCalPathsVec.push_back("EMCAL/Calib/Temperature");
 perRunCalPathsVec.push_back("GRP/CTP/Config");
 perRunCalPathsVec.push_back("GRP/CTP/CTPtiming");
 perRunCalPathsVec.push_back("GRP/CTP/LTUConfig");
 perRunCalPathsVec.push_back("GRP/CTP/Scalers");
 perRunCalPathsVec.push_back("GRP/GRP/Data");
 perRunCalPathsVec.push_back("MUON/Calib/HV");
 perRunCalPathsVec.push_back("MUON/Calib/OccupancyMap");
 perRunCalPathsVec.push_back("PMD/Calib/SMMEAN");
 perRunCalPathsVec.push_back("TPC/Calib/Goofie");
 perRunCalPathsVec.push_back("TPC/Calib/HighVoltage");
 perRunCalPathsVec.push_back("TPC/Calib/PreprocStatus");
 perRunCalPathsVec.push_back("TRD/Calib/trd_chamberStatus");
 perRunCalPathsVec.push_back("TRD/Calib/trd_envTemp");
 perRunCalPathsVec.push_back("TRD/Calib/trd_gasCO2");
 perRunCalPathsVec.push_back("TRD/Calib/trd_gasH2O");
 perRunCalPathsVec.push_back("TRD/Calib/trd_gasO2");
 perRunCalPathsVec.push_back("TRD/Calib/trd_gasOverpressure");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieCO2");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieGain");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieHv");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieN2");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofiePressure");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieTemp");
 perRunCalPathsVec.push_back("TRD/Calib/trd_goofieVelocity");
 perRunCalPathsVec.push_back("TRD/Calib/trd_hvAnodeImon");
 perRunCalPathsVec.push_back("TRD/Calib/trd_hvAnodeUmon");
 perRunCalPathsVec.push_back("TRD/Calib/trd_hvDriftImon");
 perRunCalPathsVec.push_back("TRD/Calib/trd_hvDriftUmon");

 AliCDBStorage *defaultStorage = man->GetDefaultStorage();
 defaultStorage->QueryCDB(runnr);
 TObjArray *allIdsForRun = defaultStorage->GetQueryCDBList();
 TIter next(allIdsForRun);
 AliCDBId *id = 0;
 while ((id = dynamic_cast<AliCDBId *>(next()))) {
  TString path(id->GetPath());
  Int_t firstRun = id->GetFirstRun(), lastRun = id->GetLastRun(), version = id->GetVersion();
  Bool_t isPerRun = kFALSE;
  for (Int_t i = 0; i < perRunCalPathsVec.size(); i++) {
   if (path == perRunCalPathsVec[i]) {
    isPerRun = kTRUE;
    break;
   }
  }
  // if the calibration path is not per-run, get the object if it was not
  // already present locally
  if (!isPerRun) {
   TString locPath = Form("%s/%s/Run%d_%d_v%d_s%d.root", baseFolder.Data(), path.Data(), firstRun, lastRun, version, 0);
   if (gSystem->AccessPathName(locPath.Data()))
    man->Get(path, man->GetRun(), version);
  }
 }

 // for per-run objects, save them in the drain storage after changing the run
 // range from run-run to run-infinity
 man->UnsetDrain();
 AliCDBStorage *toStorage = man->GetStorage(toURI);
 const Int_t backWindow = 10; // we will scroll back to find a valid entry not
                              // further than 2^backWindow times
 for (Int_t i = 0; i < perRunCalPathsVec.size(); i++) {
  Bool_t gotOne = kFALSE;
  Int_t previousRunNr = -1;
  Int_t attempts = 0;
  while (attempts < backWindow && gotOne == kFALSE) {
   previousRunNr = getPreviousRun(runnr, attempts++);
   if (GetLatestVersion(perRunCalPathsVec[i].Data(), previousRunNr, dbFolder) != -1) {
    gotOne = kTRUE;
    break;
   } else {
    Printf("   no run %d for object %s", previousRunNr, perRunCalPathsVec[i].Data());
   }
  }

  if (gotOne) {
   // Check whether there is already this entry in our local storage, if so
   // break
   std::stringstream globExpr;
   globExpr << "/local/cdb/" << perRunCalPathsVec[i].Data() << "/Run" << previousRunNr << "_999999999*";
   std::stringstream cmd;
   cmd << "ls " << globExpr.str() << " | wc -w";
   TString result = gSystem->GetFromPipe(cmd.str().c_str());
   if (result != "0") {
    Printf("object %s (%d) already in local repo, we skip it", perRunCalPathsVec[i].Data(), previousRunNr);
   } else {

    AliCDBEntry *remoteEntry = man->Get(perRunCalPathsVec[i].Data(), previousRunNr);
    // find locally the last coverd run-number
    AliCDBId idToInf = remoteEntry->GetId();
    AliCDBMetaData *md = remoteEntry->GetMetaData();
    TString newComment(md->GetComment());
    newComment += TString::Format("Previous run-range: %d-%d", remoteEntry->GetId().GetFirstRun(),
      remoteEntry->GetId().GetLastRun());
    TString strLocal("local");
    idToInf.SetLastStorage(strLocal);
    idToInf.SetLastRun(AliCDBRunRange::Infinity());
    remoteEntry->SetId(idToInf);
    md->SetComment(newComment);
    if (!toStorage->Put(remoteEntry))
     Printf("Could not upload object locally");
   }
  } else {
   Printf("Could not find an entry for \"%s\" in the %d checked runs !", perRunCalPathsVec[i].Data(), backWindow);
  }
 }
}

int main(int argc, char** argv)
{
    int runnumber = atoi(argv[0]);

    copyCDB(runnumber);

    return 0;
}
