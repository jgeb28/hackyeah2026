/**
 * DangerousMessagePopup
 * ---------------------------------------------------------------------------
 * Czerwony popup ostrzegawczy wyświetlany NAD treścią aplikacji.
 *
 * Na razie to czysty komponent UI osadzany w drzewie strony (Stack) — NIE jest
 * podpięty do żadnej logiki systemowej. Docelowo ten sam widok można pokazać
 * jako nakładkę nad innymi aplikacjami, np. tworząc okno pływające:
 *
 *   window.createWindow({ windowType: window.WindowType.TYPE_FLOAT })
 *
 * (wymaga uprawnienia ohos.permission.SYSTEM_FLOAT_WINDOW).
 */
@Component
export struct DangerousMessagePopup {
  /** Tytuł popupu. */
  @Prop title: string = 'Niebezpieczna wiadomość';
  /** Opcjonalny opis wyświetlany pod tytułem. */
  @Prop detail: string = '';
  /** Wywoływane przy zamknięciu popupu (klik w tło lub przycisk). */
  onDismiss: () => void = () => {};

  build() {
    Stack() {
      // Półprzezroczyste tło — przyciemnia i blokuje treść pod spodem.
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.45)')
        .onClick(() => {
          this.onDismiss();
        })

      // Czerwona karta popupu.
      Column() {
        Text('⚠')
          .fontSize(44)
          .fontColor(Color.White)

        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })

        if (this.detail.length > 0) {
          Text(this.detail)
            .fontSize(15)
            .fontColor('#FFCDD2')
            .textAlign(TextAlign.Center)
            .margin({ top: 8 })
        }

        Button('Rozumiem')
          .fontSize(16)
          .fontColor('#C62828')
          .backgroundColor(Color.White)
          .width('60%')
          .height(44)
          .margin({ top: 24 })
          .onClick(() => {
            this.onDismiss();
          })
      }
      .width('82%')
      .padding(24)
      .backgroundColor('#D32F2F')
      .borderRadius(18)
      .shadow({ radius: 30, color: '#66000000', offsetX: 0, offsetY: 10 })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }
}
