// Settings popup: the optional DeepSeek API key (the user's own, stored on-device).
@CustomDialog
export struct SettingsDialog {
  controller?: CustomDialogController;
  initialKey: string = '';
  onSave: (key: string) => void = () => {};
  @State private draftKey: string = '';

  aboutToAppear(): void {
    this.draftKey = this.initialKey;
  }

  build() {
    Column({ space: 14 }) {
      Text('Settings')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F4F7FB')
        .width('100%')

      Text('DeepSeek API key (optional)')
        .fontSize(13)
        .fontColor('#8A93A3')
        .width('100%')

      TextInput({ placeholder: 'sk-...', text: this.draftKey })
        .type(InputType.Password)
        .fontSize(14)
        .fontColor('#F4F7FB')
        .placeholderColor('#5A6472')
        .backgroundColor('#1A2029')
        .onChange((value: string) => {
          this.draftKey = value;
        })

      Row({ space: 10 }) {
        Button('Save')
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#2E77FF')
          .fontColor(Color.White)
          .onClick(() => {
            this.onSave(this.draftKey);
            this.controller?.close();
          })
        Button('Clear')
          .fontSize(14)
          .height(40)
          .layoutWeight(1)
          .backgroundColor('#232A34')
          .fontColor('#CBD3DE')
          .onClick(() => {
            this.draftKey = '';
            this.onSave('');
            this.controller?.close();
          })
      }
      .width('100%')

      Text('Stored on this device only. Used for the optional "Describe" action on some incidents.')
        .fontSize(11)
        .fontColor('#7E8798')
        .width('100%')
    }
    .width('86%')
    .padding(22)
    .backgroundColor('#11161E')
    .borderRadius(18)
    .border({ width: 1, color: '#232A34' })
  }
}
