# FHIR JSONテンプレートエンジンのご紹介

![](/assets/FacadeAndRepo.png)

1. 《パターン2》　FHIR用JSONテンプレートエンジンを使ってFHIRリソースに変換するコード例

    （FHIRファサード体験コースで行っている内容を使ってご紹介します）

    Patientテーブルに患者基本情報（ISJHospital.Patient）、Obervationテーブル（ISJHospital.Observation）に身長・体重の情報があるテーブルを用意しています。

    SQLで作成したいリソース（デモではPatientリソース）のデータを抽出し、FHIRリソースを作成する流れをご覧いただきます。
    
    また、特定のPatientに関連する全情報（デモでは、Patientリソースに紐づくObservatioリソース）を一括で返すBundleリソースの作成例もご覧いただきます（メソッドをご覧いただきます）。
    
2. 《パターン1》　FHIRリポジトリ活用例

    ファサードと同様に、PatientとObservationを利用した例でご紹介します。

    「患者基本情報が含まれるCSVを入力し、Patientリソースを作成→リポジトリへ登録」

    の流れと、

    「患者IDと通院時の身長体重情報が含まれるCSVを入力し、既存のPatientリソースと関連付けを行ったObservationリソースを作成→リポジトリへ登録」


上記内容について、どちらも**FHIRリソースではない情報からFHIRリソースを作成しています。** 

FHIRリソース用JSONを生成する部分は、どちらもパタンも同様の方法を使用しています＝日本法人で作成した **[サンプル：JSONテンプレートエンジン](https://github.com/Intersystems-jp/JSONTemplate)** を利用しています。

※製品標準に用意しているクラス群ではありませんので、利用される場合はサンプルのインポートが必要です。

## FHIRファサードの例

![](/assets/facade-intro.png)

DBに登録のあるPatientテーブルの情報を利用して、FHIRのPatientリソースを作成しGET要求の応答として返します。

![](/assets/facade-fromTable.png)

- 実行例）PatientIDを指定してPatientリソースをGETする

    localhost:62773/facade/Patient/498374


### GET要求で返信するFHIRリソースを作成する仕組みについて

作成したいリソースに合わせてJSONテンプレートを作成しています。

JSON形式のデータを操作する際、配列の繰り返しやオブジェクトの入れ子などを意識したコーディングが必要ですが、JSONテンプレートエンジンを利用したFHIRリソース専用クラスを用意することで、動的に当てはめたいデータをプロパティやパラメータで表現でき、シンプルで効率よくFHIRリソースを作成できます。

※IRIS標準機能ではないため、サンプルのインポートが必要です。

![](/assets/template-engine.png)

Patientリソースを作成する流れは以下の通りです。

```
set p=##class(FHIRTemplate.Patient).%New()
set p.LastName="山田"
set p.FirstName="太郎"
set p.LastNameKana="ヤマダ"
set p.FirstNameKana="タロウ"
set p.PatientId="P0001"
set p.Phone="03-5321-6200"
set p.Gender="male"
set p.DOB=$ZDATEH("1999-01-22",3)
do p.OutputToDevice()
```

または、プロパティ名と同じJSONを用意して、以下のように割り当てることもできます。

```
{
    "FirstName":"山田",
    "LastName":"太郎",
    "LastNameKana":"ヤマダ",
    "FirstNameKana":"タロウ",
    "PatientId":"P001",
    "Phone":"03-5321-6200",
    "Gender":"male",
    "DOB":"1999-01-22"
}
```
（ファイルに上記JSONがあるとします）
```
set file="/opt/app/src/patientsample.json"
set json={}.%FromJSONFile(file)
zwrite json
set p=##class(FHIRTemplate.Patient).%New(json)
do p.OutputToDevice()
```

JSONオブジェクトの入れ子になるような構造もあります。

抜粋したクラス定義ですが、テンプレートクラスの定義は以下の通りです（Addressプロパティ）
```
Property DOB As %Date(FORMAT = 3);

Property Gender As %String(DISPLAYLIST = ",male,female", VALUELIST = ",1,2");

/// 医療機関コード
Property MedInstCode As %String [ InitialExpression = "1311234567" ];

/// 患者ID
Property PatientId As %String;

Property Address As FHIRTemplate.DataType.Address;
```

Addressプロパティに値を割り当てる場合は、FHIRTemplate.DataType.Addressクラスのインスタンスを生成し、プロパティに値を設定し、作成したインスタンスをPatientインスタンスのAddressプロパティに割り当てるだけです。

```
set add=##class(FHIRTemplate.DataType.Address).%New()
set add.postalCode="160-0023"
set add.state="東京都"
set add.city="新宿区"
set add.line="西新宿６－１０－１"
set p.Address=add  // ここでPatientインスタンスにAddressインスタンスを割り当てています
do p.OutputToDevice()
```

単一のリソースの作成については以上です。

次に、複数のリソースを1つにまとめることのできるBundleリソースの例をご紹介します。

- REST：Patientに紐づくObservationを含めたBundleのGET

    localhost:62773/facade/Patient/498374/everything

- PatientとObservation入りBundle作成（[メソッド](/src/FHIRFacade/BuildResource.cls)）
    ```
    write ##class(FHIRFacade.BuildResource).Test(.json)
    ```

    （BundleのentryがJSON配列になっていて、その中にFHIRリソースのオブジェクトを登録しているイメージです。）

### リソース同士の紐付きについて

テーブルにデータを登録するときも、特定の患者レコードに紐づけて身長・体重データを登録する流れになるように、FHIRのリソースも同じような関係をReference（関連）として定義しています。

![](/assets/reference.png)

図例は、FHIR標準スキーマ：R4のObservationリソースのリソースコンテンツです。subjectプロパティがReference定義になっていて、Patientリソースを設定できる定義になっています。

Referenceには、リポジトリモデルの場合 **対象となるリソースの論理ID（リポジトリ内で一意となるロジカルID）** を指定しますが、ファサードモデルの場合、このIDは存在しませんので、仮IDとしてUUID（Universally Unique IDentifier）でリンク付けを行っています。

例）Observationリソースの一部
```
"subject": {
    "reference": "urn:uuid:a16f1b57-2727-4621-a6b0-bf8a03f7bf9d",
    "type": "Resource"
},
"status": "final",
"valueQuantity": {
    "value": 62,
    "unit": "kg",
    "system": "http://unitsofmeasure.org",
    "code": "31000296"
}
```


## FHIRリポジトリ活用例

以下2つの流れをご紹介します。（他形式の情報からFHIRリソースのJSONを作成する方法は、ファサードの流れと共通です）


- 患者基本情報が含まれるCSVからPatientリソースを作成する流れ

    ![](/assets/CSVtoFHIR-Patient.png)

    この例では、Interoperability（Ensemble）を利用し、CSV入力にレコードマップを使用しています。

    プロセスに送信されたメッセージを一旦JSONに変換し、JSONテンプレートエンジンを利用してPatientリソースを作成しています。

    FHIRリポジトリへREST要求を行うオペレーションはシステム提供クラスがあるので、実行時[HS.FHIRServer.Interop.Request](https://docs.intersystems.com/irisforhealthlatest/csp/documatic/%25CSP.Documatic.cls?LIBRARY=HSLIB&CLASSNAME=HS.FHIRServer.Interop.Request)を渡すだけでFHIRリポジトリに処理を依頼できます。

    リポジトリからのレスポンスは、[HS.FHIRServer.Interop.Response](https://docs.intersystems.com/irisforhealthlatest/csp/documatic/%25CSP.Documatic.cls?LIBRARY=HSLIB&CLASSNAME=HS.FHIRServer.Interop.Response)で返送されます。

    コースで行う流れでは、CSVのカラムヘッダをテンプレートクラスのプロパティ名に合わせて作成しています（大小文字も含めて合わせています）。
    >CSVから作成したメッセージをJSONに変換、変換したJSONを利用してFHIRのPatientリソースを作成しています。

    [CSVのサンプルファイル](/samples/Example-InputDataPatient.csv)

    処理例
    ```
    ClassMethod Patient(source As CSVtoFHIR.RM.Patient.Record, ByRef patient As FHIRTemplate.Patient) As %Status
    {
        #dim ex As %Exception.AbstractException
        set status=$$$OK
        try {
            //レコードマップのインスタンスをJSONストリームに変換
            $$$ThrowOnError(source.%JSONExportToStream(.jstream))
            //JSONストリームからダイナミックオブジェクトに変換
            set in={}.%FromJSON(jstream.Read())
            set in.DOB=$ZDATEH(in.DOB,8)

            //FHIRTemplate.Patientのインスタンス生成時にデータ割り当て
            set patient=##class(FHIRTemplate.Patient).%New(in)
            //Patient.addressのAddressタイプにデータ割り当て
            set address=##class(FHIRTemplate.DataType.Address).%New(in)
            set patient.Address=address

            //GenderをFHIR R4 Patientリソースに合わせて変更
            set patient.Gender=$select(in.Gender="M":1,1:2)

        }
        catch ex {
            set status=ex.AsStatus()
        }
        return status
    }
    ```

    メモ：レコードマップのクラス定義：CSVtoFHIR.RM.Patient.Record のスーパークラスには%JSON.Adaptorを追加しています。
    ```
    Class CSVtoFHIR.RM.Patient.Record Extends (%Persistent, %XML.Adaptor, Ens.Request, EnsLib.RecordMap.Base, %JSON.Adaptor) [ Inheritance = right, ProcedureBlock ]
    ```

- 実演：Patient用CSVを指定ディレクトリに配置すると2件のPatientリソースが登録されます。

    - FHIRリポジトリにPatientリソースがないことを確認
    
        localhost:62773/csp/healthshare/test/fhir/r4/Patient
    
    - CSVファイル取り込み

        使用するファイル：[InputDataPatient.csv](/samples/InputDataPatient.csv)

    - FHIRリポジトリ確認

        localhost:62773/csp/healthshare/test/fhir/r4/Patient




- 身長・体重が含まれるCSVからObservationリソースを登録する流れ（複数一括登録）

    <font color="red"> **以下の流れを試す前に、Observation用テンプレートクラスをCSVからFHIRへの変換用に変更してください。** </font>

    【方法】IRISに接続した状態で、[csvtofhir-ObservationBodyMeasurement.cls](src/FHIRCustom/csvtofhir-ObservationBodyMeasurement.cls)クラスをCtrl＋Sで保存します（インポート＋コンパイルが実行されます）。



    ![](/assets/CSVtoFHIR-Observation.png)

    複数行を一括で入力→Observationに変換→複数のObservationリソースをBundleにまとめてPOST要求送信 の流れで処理しています。
    
    サンプル：[Example-InputDataLabTest.csv](/samples/Example-InputDataLabTest.csv)

    ![](/assets/CSVtoFHIR-ObservataionMapping.png)

    登録時、特定のPatientリソースに関連したObservationであることをリソースのReferenceで設定する必要があるので、CSVに含まれるPatientIdの値から、対象PatientのリソースIDを取得しています。
    （FHIRリポジトリに対してPatientリソースのリソースIDを取得するため、GET要求を実行しています）

    実行するGET要求のURL例は以下の通りです。

    例：`localhost:62773/csp/healthshare/test/fhir/r4/Patient?identifier=urn:oid:1.2.392.100495.20.3.51.11311234567|191922`
    
    クエリパラメータの identifierを利用します。（ご参考：クエリパラメータの指定方法についても、FHIR標準スキーマで提示されています：[PatientのSearchParameter](https://www.hl7.org/fhir/patient.html#search)）

    実際の流れは、トレースを確認しながらご紹介します。

- 実演：

    - FHIRリポジトリにObservationリソースがないことを確認
    
        localhost:62773/csp/healthshare/test/fhir/r4/Observation
    
    - CSVファイル取り込み

        使用するファイル：[InputDataLabTest.csv](/samples/InputDataLabTest.csv)

        PatientリソースのIDを取得する流れ(GET要求の実施)
        ![](/assets/CSVtoFHIR-GET-PatientID.png)

        GET要求の結果
        ![](/assets/CSVtoFHIR-GET-PatientID-Response.png)

        Observationリソースの一括登録（BundleのPOST）
        ![](/assets/CSVtoFHIR-ObservationPOST-Request.png)

        Observationリソースの登録結果
        ![](/assets/CSVtoFHIR-ObservationPOST-Response.png)

    - FHIRリポジトリ確認（Observationが4件返る予定）

        localhost:62773/csp/healthshare/test/fhir/r4/Observation

        Observationリソース登録時、PatientリソースのリソースIDを以下のように設定しています。（リポジトリ内で一意となる値を指定します。同一リポジトリ内のリファレンス設定の場合、Webサーバやエンドポイントの記述は省略できます）

        ```
        "subject": {
            "reference": "Patient/1"
        },
        ```

    - Patientリソースとの関連を確認（リソースID=1の患者に紐づくObservationが登録されたか確認：3件返る予定）

        localhost:62773/csp/healthshare/test/fhir/r4/Patient/1/$everything

