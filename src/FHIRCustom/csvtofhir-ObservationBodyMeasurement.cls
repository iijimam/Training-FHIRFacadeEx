Class FHIRCustom.ObservationBodyMeasurement Extends FHIRTemplate.Observation
{

Property Category As list Of FHIRCustom.CodeableConcept.ObservationCategory;

Property Code As FHIRCustom.CodeableConcept.BodyMeasurementCode;

/// JSON出力する際のテンプレート
/// https://jpfhir.jp/jpcoreV1/ObservationCommon を参考に作成
/// JSONの値の文字列に#(..プロパティ名)#または#(..#パラメータ名)#を指定することで
/// プロパティの値をJSON形式で出力できます。
/// プロパティの型がJSONTemplate.Baseを継承したクラスの場合、
/// そのクラスのテンプレートからJSON出力します。
XData Template [ MimeType = application/json ]
{
{
  "resourceType": "#(..#ResourceType)#",
  "category": [ "#(..Category)#" ],
  "code": "#(..Code)#",
  "effectiveDateTime": "#(..EffectiveDateTime)#",
  "subject":  { "reference":"#(..PatientResourceId)#" },
  "status": "final",
  "valueQuantity": "#(..ValueQuantity(FHIRTemplate.DataType.Quantity))#"
}
}

Property PatientResourceId As %String;

}
