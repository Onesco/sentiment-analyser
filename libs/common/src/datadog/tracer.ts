import tracer from 'dd-trace';
tracer.init({
  logInjection: true,
}); // initialized in a different file to avoid hoisting.

// import formats from 'dd-trace/ext/formats';

// export class Logger {
//   log(level, message) {
//     const span = tracer.scope().active();
//     const time = new Date().toISOString();
//     const record = { time, level, message };

//     if (span) {
//       tracer.inject(span.context(), formats.LOG, record);
//     }

//     console.log(JSON.stringify(record));
//   }
// }

export default tracer;
