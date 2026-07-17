import { Component } from '@angular/core';

@Component({
  selector: 'app-root',
  standalone: true,
  template: `<h1>{{ titre }}</h1>`
})
export class AppComponent {
  protected readonly titre = 'Formuloo Tracker';
}
